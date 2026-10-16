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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require_relative "../spec_helper"

RSpec.describe "LDAP group filter administration spec", :js do
  let(:admin) { create(:admin) }

  before do
    login_as admin
  end

  context "with EE", with_ee: %i[ldap_groups] do
    context "when providing seed variables",
            :settings_reset,
            with_env: {
              OPENPROJECT_SEED_LDAP_FOO_HOST: "localhost",
              OPENPROJECT_SEED_LDAP_FOO_PORT: "12389",
              OPENPROJECT_SEED_LDAP_FOO_SECURITY: "plain_ldap",
              OPENPROJECT_SEED_LDAP_FOO_TLS__VERIFY: "false",
              OPENPROJECT_SEED_LDAP_FOO_BINDUSER: "uid=admin,ou=system",
              OPENPROJECT_SEED_LDAP_FOO_BINDPASSWORD: "secret",
              OPENPROJECT_SEED_LDAP_FOO_BASEDN: "dc=example,dc=com",
              OPENPROJECT_SEED_LDAP_FOO_FILTER: "(uid=*)",
              OPENPROJECT_SEED_LDAP_FOO_SYNC__USERS: "true",
              OPENPROJECT_SEED_LDAP_FOO_LOGIN__MAPPING: "uid",
              OPENPROJECT_SEED_LDAP_FOO_FIRSTNAME__MAPPING: "givenName",
              OPENPROJECT_SEED_LDAP_FOO_LASTNAME__MAPPING: "sn",
              OPENPROJECT_SEED_LDAP_FOO_MAIL__MAPPING: "mail",
              OPENPROJECT_SEED_LDAP_FOO_ADMIN__MAPPING: "",
              OPENPROJECT_SEED_LDAP_FOO_GROUPFILTER_BAR_BASE: "ou=groups,dc=example,dc=com",
              OPENPROJECT_SEED_LDAP_FOO_GROUPFILTER_BAR_FILTER: "(cn=*)",
              OPENPROJECT_SEED_LDAP_FOO_GROUPFILTER_BAR_SYNC__USERS: "true",
              OPENPROJECT_SEED_LDAP_FOO_GROUPFILTER_BAR_GROUP__ATTRIBUTE: "dn"
            } do
      it "blocks editing of the filter" do
        reset(:seed_ldap)
        allow(LdapGroups::SynchronizationJob).to receive(:perform_now)
        EnvData::LdapSeeder.new({}).seed_data!

        visit ldap_groups_synchronized_groups_path
        expect(page).to have_text "bar"
        page.find("td.name a", text: "bar").click

        expect(page).to have_text I18n.t(:label_seeded_from_env_warning)
        expect(page).to have_no_link "Edit"
        expect(page).to have_no_link "Delete"
      end
    end
  end
end
