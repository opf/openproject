# frozen_string_literal: true

require "spec_helper"

RSpec.describe TestManagement::TestCasesQuery do
  let(:project) { create(:project) }
  let(:root) { create(:tm_suite, project:, name: "Accounts") }
  let(:child) { create(:tm_suite, project:, parent: root, name: "Sign in") }
  let(:other_folder) { create(:tm_suite, project:, name: "Reports") }
  let!(:in_root) { create(:tm_test_case, project:, suite: root, title: "Root case", priority: "high") }
  let!(:in_child) { create(:tm_test_case, project:, suite: child, title: "Child case", priority: "low") }
  let!(:elsewhere) { create(:tm_test_case, project:, suite: other_folder, title: "Report case") }
  let!(:unfiled) { create(:tm_test_case, project:, title: "Loose case") }
  let!(:deleted) { create(:tm_test_case, project:, suite: root, title: "Gone").tap(&:soft_delete!) }

  def query(params = {})
    described_class.new(project, params)
  end

  it "returns all not deleted cases for the project scope" do
    expect(query(suite_id: root.id.to_s, q: "x").results("project"))
      .to contain_exactly(in_root, in_child, elsewhere, unfiled)
  end

  it "includes subfolders for the folder scope" do
    expect(query(suite_id: root.id.to_s, priority: "high").results("folder")).to contain_exactly(in_root, in_child)
  end

  it "selects unfiled cases for suite_id=root" do
    q = query(suite_id: "root")
    expect(q).to be_unfiled
    expect(q.results).to contain_exactly(unfiled)
  end

  it "selects soft-deleted cases for suite_id=deleted" do
    q = query(suite_id: "deleted")
    expect(q).to be_deleted
    expect(q.results).to contain_exactly(deleted)
  end

  it "applies search, status and priority on top of the folder for the filter scope" do
    expect(query(suite_id: root.id.to_s, priority: "low").results("filter")).to contain_exactly(in_child)
    expect(query(q: "report").results("filter")).to contain_exactly(elsewhere)
    expect(query(status: "nope").results("filter")).to be_empty
  end

  it "works out the current scope and the params that reproduce a scope" do
    expect(query.current_scope).to eq("project")
    expect(query(suite_id: root.id.to_s).current_scope).to eq("folder")

    q = query(suite_id: root.id.to_s, q: "case", status: "", other: "x")
    expect(q.current_scope).to eq("filter")
    expect(q.params_for("filter")).to eq(suite_id: root.id.to_s, q: "case")
    expect(q.params_for("folder")).to eq(suite_id: root.id.to_s)
    expect(q.params_for("project")).to eq({})
  end

  it "accepts ActionController::Parameters" do
    params = ActionController::Parameters.new(suite_id: child.id.to_s, controller: "x")
    expect(query(params).results).to contain_exactly(in_child)
  end
end
