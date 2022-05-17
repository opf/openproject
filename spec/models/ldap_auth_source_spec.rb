#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2022 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require 'spec_helper'

describe LdapAuthSource, type: :model do
  it 'should create' do
    a = LdapAuthSource.new(name: 'My LDAP', host: 'ldap.example.net', port: 389, base_dn: 'dc=example,dc=net',
                           attr_login: 'sAMAccountName')
    expect(a.save).to eq true
  end

  it 'should strip ldap attributes' do
    a = LdapAuthSource.new(name: 'My LDAP', host: 'ldap.example.net', port: 389, base_dn: 'dc=example,dc=net', attr_login: 'sAMAccountName',
                           attr_firstname: 'givenName ')
    expect(a.save).to eq true
    expect(a.reload.attr_firstname).to eq 'givenName'
  end

  describe 'overriding tls_options',
           with_config: { ldap_tls_options: { ca_file: '/path/to/ca/file' } } do
    it 'sets the encryption options for start_tls' do
      ldap = LdapAuthSource.new tls_mode: :start_tls
      expect(ldap.send(:ldap_encryption)).to eq(method: :start_tls, tls_options: { 'ca_file' => '/path/to/ca/file' })
    end

    it 'does nothing for plain_ldap' do
      ldap = LdapAuthSource.new tls_mode: :plain_ldap
      expect(ldap.send(:ldap_encryption)).to eq nil
    end
  end

  describe 'admin attribute mapping' do
    let(:auth_source) do
      build :ldap_auth_source,
            attr_login: 'uid',
            attr_firstname: 'givenName',
            attr_lastname: 'sn',
            attr_mail: 'mail',
            attr_admin: attr_admin
    end
    let(:entry) do
      Net::LDAP::Entry.new('uid=login,foo=bar').tap do |entry|
        entry['uid'] = 'login'
        entry['givenName'] = 'abc'
        entry['sn'] = 'lastname'
        entry['mail'] = 'some@example.org'
        entry['admin'] = admin_value
      end
    end

    subject { auth_source.get_user_attributes_from_ldap_entry(entry) }

    context 'when attribute defined and not present' do
      let(:attr_admin) { 'admin' }
      let(:admin_value) { nil }

      it 'returns it as false' do
        expect(subject).to have_key(:admin)
        expect(subject[:admin]).to be false
      end
    end

    context 'when attribute defined and castable number' do
      let(:attr_admin) { 'admin' }
      let(:admin_value) { '1' }

      it 'does return the mapping' do
        expect(subject).to have_key(:admin)
        expect(subject[:admin]).to be true
      end
    end

    context 'when attribute defined and boolean' do
      let(:attr_admin) { 'admin' }
      let(:admin_value) { false }

      it 'does return the mapping' do
        expect(subject).to have_key(:admin)
        expect(subject[:admin]).to be false
      end
    end

    context 'when attribute defined and true string' do
      let(:attr_admin) { 'admin' }
      let(:admin_value) { 'true' }

      it 'does return the mapping' do
        expect(subject).to have_key(:admin)
        expect(subject[:admin]).to be true
      end
    end

    context 'when attribute defined and false string' do
      let(:attr_admin) { 'admin' }
      let(:admin_value) { 'false' }

      it 'does return the mapping' do
        expect(subject).to have_key(:admin)
        expect(subject[:admin]).to be false
      end
    end

    context 'when attribute not defined and set' do
      let(:attr_admin) { nil }
      let(:admin_value) { true }

      it 'does not return an admin mapping' do
        expect(subject).not_to have_key(:admin)
      end
    end
  end

  describe 'with live LDAP' do
    before(:all) do
      ldif = Rails.root.join('spec/fixtures/ldap/users.ldif')
      @ldap_server = Ladle::Server.new(quiet: false, port: ParallelHelper.port_for_ldap.to_s, domain: 'dc=example,dc=com',
                                       ldif: ldif).start
    end

    after(:all) do
      @ldap_server.stop
    end

    # Ldap has three users aa729, bb459, cc414
    let(:ldap) do
      create :ldap_auth_source,
             port: ParallelHelper.port_for_ldap.to_s,
             account: 'uid=admin,ou=system',
             account_password: 'secret',
             base_dn: 'ou=people,dc=example,dc=com',
             filter_string: filter_string,
             onthefly_register: true,
             attr_login: 'uid',
             attr_firstname: 'givenName',
             attr_lastname: 'sn',
             attr_mail: 'mail'
    end

    let(:filter_string) { nil }

    context '#authenticate' do
      context 'with a valid LDAP user' do
        it 'should return the user attributes' do
          attributes = ldap.authenticate('bb459', 'niwdlab')
          expect(attributes).to be_kind_of Hash
          expect(attributes[:firstname]).to eq 'Belle'
          expect(attributes[:lastname]).to eq 'Baldwin'
          expect(attributes[:mail]).to eq 'belle@example.org'
          expect(attributes[:auth_source_id]).to eq ldap.id

          expect { User.new(attributes) }.not_to raise_error
        end
      end

      context 'with an invalid LDAP user' do
        it 'should return nil' do
          expect(ldap.authenticate('nouser', 'whatever')).to eq nil
        end
      end

      context 'without a login' do
        it 'should return nil' do
          expect(ldap.authenticate('', 'whatever')).to eq nil
        end
      end

      context 'without a password' do
        it 'should return nil' do
          expect(ldap.authenticate('whatever', 'nil')).to eq nil
        end
      end

      context 'with a filter string returning only users with a*' do
        let(:filter_string) { '(uid=a*)' }

        it 'no longer authenticates bb254' do
          expect(ldap.authenticate('bb459', 'niwdlab')).to eq nil
        end

        it 'still authenticates aa729' do
          attributes = ldap.authenticate('aa729', 'smada')
          expect(attributes[:firstname]).to eq 'Alexandra'
        end
      end
    end
  end
end
