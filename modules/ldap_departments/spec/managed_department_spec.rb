# frozen_string_literal: true

require_relative "spec_helper"

RSpec.describe "LDAP-managed department locking", :aggregate_failures do # rubocop:disable RSpec/DescribeClass
  let(:admin) { create(:admin) }
  let(:department) { create(:department, lastname: "Engineering") }

  describe "Group#ldap_managed?" do
    it "is false for an organizational unit without a mapping" do
      expect(department.ldap_managed?).to be(false)
    end

    it "is true for an organizational unit with a mapping" do
      create(:ldap_synchronized_department, group: department)

      expect(department.reload.ldap_managed?).to be(true)
    end

    it "is false for a regular group without querying the mapping" do
      group = create(:group)
      allow(group).to receive(:ldap_departments_synchronized_departments).and_call_original

      expect(group.ldap_managed?).to be(false)
      expect(group).not_to have_received(:ldap_departments_synchronized_departments)
    end

    it "is false for an unsaved group" do
      expect(Group.new.ldap_managed?).to be(false)
    end
  end

  context "when the department is mapped from LDAP" do
    before { create(:ldap_synchronized_department, group: department) }

    it "reports the department as managed" do
      expect(department.reload.ldap_managed?).to be(true)
    end

    it "rejects renaming by an admin" do
      call = Groups::UpdateService.new(user: admin, model: department).call(name: "Renamed")

      expect(call).to be_failure
      expect(department.reload.name).to eq("Engineering")
    end

    it "rejects deletion by an admin" do
      call = Groups::DeleteService.new(user: admin, model: department).call

      expect(call).to be_failure
      expect(Group.exists?(department.id)).to be(true)
    end

    it "allows the synchronization itself to change it" do
      call = Groups::UpdateService
        .new(user: User.system, model: department, contract_class: Groups::SyncUpdateContract)
        .call(name: "Renamed")

      expect(call).to be_success
      expect(department.reload.name).to eq("Renamed")
    end
  end

  context "when the department is not managed" do
    it "allows an admin to rename it" do
      call = Groups::UpdateService.new(user: admin, model: department).call(name: "Renamed")

      expect(call).to be_success
    end
  end

  describe "adding a child department under a managed parent" do
    before { create(:ldap_synchronized_department, group: department) }

    it "is rejected for an admin" do
      call = Groups::CreateService
        .new(user: admin)
        .call(name: "Child", organizational_unit: true, parent_id: department.id)

      expect(call).to be_failure
      expect(call.errors.symbols_for(:parent_id)).to include(:parent_ldap_managed)
    end

    it "is allowed for the synchronization" do
      call = Groups::CreateService
        .new(user: User.system, contract_class: Groups::SyncCreateContract)
        .call(name: "Child", organizational_unit: true, parent_id: department.id)

      expect(call).to be_success
      expect(call.result.parent_id).to eq(department.id)
    end
  end

  describe "moving a user out of a managed department" do
    let(:managed) { create(:department, lastname: "Managed dept") }
    let(:manual) { create(:department, lastname: "Manual dept") }
    let(:user) { create(:user) }
    let(:synced) { create(:ldap_synchronized_department, group: managed) }

    before { synced.add_members!([user]) }

    it "is rejected with a dedicated error and leaves the user in the managed department" do
      call = Departments::AddUserService
        .new(manual, user: admin)
        .call(user_id: user.id, remove_from_previous_department: true)

      expect(call).to be_failure
      expect(call.errors.symbols_for(:base)).to include(:user_in_ldap_managed_department)
      expect(managed.reload.users).to include(user)
      expect(manual.reload.users).not_to include(user)
    end
  end

  describe "sibling-scoped name uniqueness" do
    let(:it_dep) { create(:department, lastname: "IT") }
    let(:hr_dep) { create(:department, lastname: "HR") }

    it "allows the same name under different parents" do
      first = build(:department, lastname: "Support", parent: it_dep)
      second = build(:department, lastname: "Support", parent: hr_dep)

      expect(first).to be_valid
      expect(second.tap(&:valid?)).to be_valid
      expect { first.save! && second.save! }.not_to raise_error
    end

    it "rejects the same name among siblings" do
      create(:department, lastname: "Support", parent: it_dep)
      duplicate = build(:department, lastname: "Support", parent: it_dep)

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:name]).to be_present
    end
  end
end
