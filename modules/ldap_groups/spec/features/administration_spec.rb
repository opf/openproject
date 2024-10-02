require_relative "../spec_helper"

RSpec.describe "LDAP group sync administration spec", :js do
  let(:admin) { create(:admin) }

  before do
    login_as admin
    visit ldap_groups_synchronized_groups_path
  end

  context "without EE" do
    it "shows upsale" do
      expect(page).to have_css(".upsale-notification")
    end
  end

  context "with EE", with_ee: %i[ldap_groups] do
    let!(:group) { create(:group, lastname: "foo") }
    let!(:auth_source) { create(:ldap_auth_source, name: "ldap") }

    it "allows synced group administration flow" do
      expect(page).to have_no_css(".upsale-notification")

      # Open create menu
      page.find_test_selector("op-admin-synchronized-groups--button-new", text: I18n.t(:button_add)).click
      # Create group
      page.find_test_selector("op-admin-synchronized-groups--new-groups",
                              text: I18n.t("ldap_groups.synchronized_groups.singular")).click

      SeleniumHubWaiter.wait

      select "ldap", from: "synchronized_group_ldap_auth_source_id"
      select "foo", from: "synchronized_group_group_id"
      fill_in "synchronized_group_dn", with: "cn=foo,ou=groups,dc=example,dc=com"
      check "synchronized_group_sync_users"

      click_on "Create"
      expect_flash(message: I18n.t(:notice_successful_create))
      expect(page).to have_css("td.dn", text: "cn=foo,ou=groups,dc=example,dc=com")
      expect(page).to have_css("td.ldap_auth_source", text: "ldap")
      expect(page).to have_css("td.group", text: "foo")
      expect(page).to have_css("td.users", text: "0")

      # Show entry
      SeleniumHubWaiter.wait
      find("td.dn a").click
      expect(page).to have_css ".generic-table--empty-row"

      # Check created group
      sync = LdapGroups::SynchronizedGroup.last
      expect(sync.group_id).to eq(group.id)
      expect(sync.ldap_auth_source_id).to eq(auth_source.id)
      expect(sync.dn).to eq "cn=foo,ou=groups,dc=example,dc=com"

      # Assume we have a membership
      sync.users.create user_id: admin.id
      visit ldap_groups_synchronized_group_path(sync)
      expect(page).to have_css "td.user", text: admin.name

      memberships = sync.users.pluck(:id)

      visit ldap_groups_synchronized_groups_path
      expect_angular_frontend_initialized
      find(".buttons a", text: "Delete").click

      SeleniumHubWaiter.wait
      find(".danger-zone--verification input").set "cn=foo,ou=groups,dc=example,dc=com"

      SeleniumHubWaiter.wait
      click_on "Delete"

      expect_flash(message: I18n.t(:notice_successful_delete))
      expect(page).to have_css ".generic-table--empty-row"

      expect(LdapGroups::Membership.where(id: memberships)).to be_empty
    end
  end
end
