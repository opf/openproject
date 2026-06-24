# frozen_string_literal: true

require_relative "../../../spec_helper"

RSpec.describe Admin::Departments::HierarchyLayoutComponent, type: :component do
  let(:department) { create(:department, lastname: "IT") }

  context "when the active department is not managed by LDAP" do
    it "offers the add menu" do
      render_inline(described_class.new(groups: [department], active_group: department))

      expect(page).to have_css("action-menu")
      expect(page).to have_button(I18n.t(:button_add))
    end
  end

  context "when the active department is managed by LDAP" do
    before { create(:ldap_synchronized_department, group: department) }

    it "hides the add menu" do
      render_inline(described_class.new(groups: [department], active_group: department.reload))

      expect(page).to have_no_css("action-menu")
      expect(page).to have_no_button(I18n.t(:button_add))
    end
  end
end
