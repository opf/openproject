# frozen_string_literal: true

require_relative "../../../spec_helper"

RSpec.describe Admin::Departments::DepartmentRowComponent, type: :component do
  let(:department) { create(:department, lastname: "IT") }

  context "when the department is not managed by LDAP" do
    it "renders the action menu" do
      render_inline(described_class.new(department:))

      expect(page).to have_css("action-menu")
      expect(page).to have_no_text(I18n.t(:label_managed_by_ldap))
    end
  end

  context "when the department is managed by LDAP" do
    before { create(:ldap_synchronized_department, group: department) }

    it "renders a managed label instead of the action menu" do
      render_inline(described_class.new(department: department.reload))

      expect(page).to have_text(I18n.t(:label_managed_by_ldap))
      expect(page).to have_no_css("action-menu")
    end
  end
end
