# frozen_string_literal: true

require_relative "../../../spec_helper"

RSpec.describe Admin::Departments::ChangeParentDialogComponent, type: :component do
  let(:moved) { create(:department, lastname: "Moved") }
  let(:managed) { create(:department, lastname: "Managed") }
  let(:manual) { create(:department, lastname: "Manual") }

  before do
    moved
    manual
    create(:ldap_synchronized_department, group: managed)
  end

  it "disables LDAP-managed departments as parent candidates" do
    departments = Group.organizational_units.with_detail.in_tree_order

    render_inline(described_class.new(department: moved, departments:))

    expect(page).to have_css("[data-value='#{managed.id}'][aria-disabled='true']")
    expect(page).to have_css("[data-value='#{manual.id}']")
    expect(page).to have_no_css("[data-value='#{manual.id}'][aria-disabled='true']")
  end
end
