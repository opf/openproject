# frozen_string_literal: true

require_relative "../../spec_helper"

RSpec.describe LdapDepartments::SynchronizedDepartment do
  let(:user) { create(:user) }
  let(:department) { create(:department, lastname: "Frontend") }
  let(:tree) { create(:ldap_synchronized_tree) }
  let!(:synchronized_department) do
    create(:ldap_synchronized_department, synchronized_tree: tree, group: department)
  end

  before { synchronized_department.add_members!([user]) }

  describe "destroying the mapping" do
    it "keeps the department and its members, dropping only the tracking record" do
      expect { synchronized_department.destroy }
        .to change(LdapDepartments::Membership, :count).by(-1)

      expect(Group.exists?(department.id)).to be(true)
      expect(department.reload.users).to include(user)
    end
  end

  describe "destroying the parent tree" do
    it "unlinks its departments while keeping them and their members" do
      expect { tree.destroy }
        .to change(described_class, :count).by(-1)
        .and change(LdapDepartments::Membership, :count).by(-1)

      expect(Group.exists?(department.id)).to be(true)
      expect(department.reload.users).to include(user)
    end
  end
end
