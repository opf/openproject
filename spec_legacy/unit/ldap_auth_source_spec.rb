#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++
require 'legacy_spec_helper'

describe LdapAuthSource, type: :model do
  fixtures :all

  it 'should create' do
    a = LdapAuthSource.new(name: 'My LDAP', host: 'ldap.example.net', port: 389, base_dn: 'dc=example,dc=net', attr_login: 'sAMAccountName')
    assert a.save
  end

  it 'should strip ldap attributes' do
    a = LdapAuthSource.new(name: 'My LDAP', host: 'ldap.example.net', port: 389, base_dn: 'dc=example,dc=net', attr_login: 'sAMAccountName',
                           attr_firstname: 'givenName ')
    assert a.save
    assert_equal 'givenName', a.reload.attr_firstname
  end

  if ldap_configured?
    context '#authenticate' do
      before do
        @auth = LdapAuthSource.find(1)
      end

      context 'with a valid LDAP user' do
        it 'should return the user attributes' do
          attributes =  @auth.authenticate('example1', '123456')
          assert attributes.is_a?(Hash), 'An hash was not returned'
          assert_equal 'Example', attributes[:firstname]
          assert_equal 'One', attributes[:lastname]
          assert_equal 'example1@redmine.org', attributes[:mail]
          assert_equal @auth.id, attributes[:auth_source_id]
          attributes.keys.each do |attribute|
            assert User.new.respond_to?("#{attribute}="), "Unexpected :#{attribute} attribute returned"
          end
        end
      end

      context 'with an invalid LDAP user' do
        it 'should return nil' do
          assert_equal nil, @auth.authenticate('nouser', '123456')
        end
      end

      context 'without a login' do
        it 'should return nil' do
          assert_equal nil, @auth.authenticate('', '123456')
        end
      end

      context 'without a password' do
        it 'should return nil' do
          assert_equal nil, @auth.authenticate('edavis', '')
        end
      end
    end
  else
    puts '(Test LDAP server not configured)'
  end
end
