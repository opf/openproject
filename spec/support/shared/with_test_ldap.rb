#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
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
require "ladle"

RSpec.shared_context "with temporary LDAP" do
  before(:all) do
    ldif = Rails.root.join("spec/fixtures/ldap/users.ldif")
    @ldap_server = Ladle::Server.new(quiet: false,
                                     port: ParallelHelper.port_for_ldap.to_s,
                                     domain: "dc=example,dc=com",
                                     ldif:).start
  end

  after(:all) do
    @ldap_server&.stop # rubocop:disable RSpec/InstanceVariable
  end

  # Ldap has:
  # three users aa729, bb459, cc414
  # two groups foo (aa729), bar(aa729, bb459, cc414)
  let!(:ldap_auth_source) do
    create(:ldap_auth_source,
           port: ParallelHelper.port_for_ldap.to_s,
           account: "uid=admin,ou=system",
           account_password: "secret",
           base_dn: "ou=people,dc=example,dc=com",
           onthefly_register:,
           filter_string: ldap_filter,
           attr_login: "uid",
           attr_firstname:,
           attr_lastname:,
           attr_mail:,
           attr_admin:)
  end

  let(:onthefly_register) { false }
  let(:ldap_filter) { nil }
  let(:attr_firstname) { "givenName" }
  let(:attr_lastname) { "sn" }
  let(:attr_mail) { "mail" }
  let(:attr_admin) { "isAdmin" }
end
