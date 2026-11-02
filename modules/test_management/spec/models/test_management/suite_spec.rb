# frozen_string_literal: true

require "spec_helper"

RSpec.describe TestManagement::Suite do
  let(:project) { create(:project, enabled_module_names: %i[test_management]) }
  let!(:root) { create(:tm_suite, project:, name: "Accounts") }
  let!(:child) { create(:tm_suite, project:, parent: root, name: "Sign in") }
  let!(:grandchild) { create(:tm_suite, project:, parent: child, name: "Two factor") }

  it "requires a name unique among siblings" do
    expect(build(:tm_suite, project:, name: "")).not_to be_valid
    expect(build(:tm_suite, project:, name: "Accounts")).not_to be_valid
    expect(build(:tm_suite, project:, parent: root, name: "Sign in")).not_to be_valid
    expect(build(:tm_suite, project:, parent: child, name: "Sign in")).to be_valid
  end

  it "enforces root-folder uniqueness at the database (NULL parent_id)" do
    now = Time.current
    expect do
      described_class.insert!({
                                project_id: project.id,
                                parent_id: nil,
                                name: "Accounts",
                                position: 0,
                                created_at: now,
                                updated_at: now
                              })
    end.to raise_error(ActiveRecord::RecordNotUnique)
  end

  it "returns subtree ids" do
    expect(described_class.subtree_ids(project, [root.id])).to contain_exactly(root.id, child.id, grandchild.id)
    expect(described_class.subtree_ids(project, [child.id])).to contain_exactly(child.id, grandchild.id)
  end

  it "builds the folder path" do
    expect(grandchild.path_name).to eq("Accounts / Sign in / Two factor")
    expect(grandchild.path_name(" > ")).to eq("Accounts > Sign in > Two factor")
  end

  it "counts live cases, recursively" do
    create(:tm_test_case, project:, suite: root)
    create(:tm_test_case, project:, suite: grandchild)
    create(:tm_test_case, project:, suite: grandchild, deleted_at: Time.current)

    expect(root.cases_count).to eq(1)
    expect(root.recursive_cases_count).to eq(2)
  end

  it "destroys subfolders and unfiles their cases" do
    test_case = create(:tm_test_case, project:, suite: grandchild)
    root.destroy

    expect(described_class.where(project:)).to be_empty
    expect(test_case.reload.suite_id).to be_nil
  end

  it "orders by position then name and exposes roots" do
    expect(described_class.where(project:).roots).to contain_exactly(root)
  end
end
