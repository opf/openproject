require "spec_helper"

RSpec.describe LdapGroups::Membership do
  describe "destroy" do
    let(:synchronized_group) { create(:ldap_synchronized_group, group:) }
    let(:group) { create(:group) }
    let(:user) { create(:user) }

    before do
      User.system.run_given do
        synchronized_group.add_members! [user]
      end
    end

    it "is removed when the user is destroyed" do
      expect(user.ldap_groups_memberships.count).to eq 1
      membership = user.ldap_groups_memberships.first
      expect(membership.group).to eq(synchronized_group)
      expect(membership.user).to eq(user)
      expect(synchronized_group.users.count).to eq(1)

      user.destroy!
      synchronized_group.reload

      expect { membership.reload }.to raise_error(ActiveRecord::RecordNotFound)
      expect(synchronized_group.users.count).to eq(0)
    end
  end
end
