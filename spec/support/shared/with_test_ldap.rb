#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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
require 'ladle'

shared_context 'with temporary LDAP' do
  # rubocop:disable RSpec/InstanceVariable
  before(:all) do
    ldif = Rails.root.join('spec/fixtures/ldap/users.ldif')
    @ldap_server = Ladle::Server.new(quiet: false,
                                     port: ParallelHelper.port_for_ldap.to_s,
                                     domain: 'dc=example,dc=com',
                                     ldif:).start
  end

  after(:all) do
    @ldap_server.stop
  end
  # rubocop:enable RSpec/InstanceVariable

  # Ldap has:
  # three users aa729, bb459, cc414
  # two groups foo (aa729), bar(aa729, bb459, cc414)
  let(:auth_source) do
    create :ldap_auth_source,
           port: ParallelHelper.port_for_ldap.to_s,
           account: 'uid=admin,ou=system',
           account_password: 'secret',
           base_dn: 'ou=people,dc=example,dc=com',
           onthefly_register:,
           filter_string: ldap_filter,
           attr_login: 'uid',
           attr_firstname: 'givenName',
           attr_lastname: 'sn',
           attr_mail: 'mail'
  end

  let(:onthefly_register) { false }
  let(:ldap_filter) { nil }
end
