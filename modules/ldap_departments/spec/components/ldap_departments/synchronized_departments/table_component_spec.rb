# frozen_string_literal: true

require_relative "../../../spec_helper"

RSpec.describe LdapDepartments::SynchronizedDepartments::TableComponent, type: :component do
  let(:tree) { create(:ldap_synchronized_tree) }
  let(:hr) { create(:department, lastname: "Human Resources") }
  let(:support) { create(:department, lastname: "Support", parent: hr) }
  let!(:hr_sync) { create(:ldap_synchronized_department, synchronized_tree: tree, group: hr) }
  let!(:support_sync) { create(:ldap_synchronized_department, synchronized_tree: tree, group: support) }

  it "renders the full department path instead of only the leaf name" do
    render_inline(described_class.new(rows: tree.synchronized_departments.includes(group: :group_detail)))

    expect(page).to have_text("Human Resources / Support")
  end
end
