# frozen_string_literal: true

require_relative "../../../spec_helper"

RSpec.describe Admin::Departments::DetailBlankslateComponent, type: :component do
  let(:department) { create(:department, lastname: "IT") }

  context "when the department is not managed by LDAP" do
    it "invites adding departments or users" do
      render_inline(described_class.new(group: department))

      expect(page).to have_text(I18n.t("departments.detail_blankslate.heading"))
      expect(page).to have_no_text(I18n.t("departments.detail_blankslate.managed_heading"))
    end
  end

  context "when the department is managed by LDAP" do
    before { create(:ldap_synchronized_department, group: department) }

    it "explains that it is managed and cannot be edited manually" do
      render_inline(described_class.new(group: department.reload))

      expect(page).to have_text(I18n.t("departments.detail_blankslate.managed_heading"))
      expect(page).to have_text(I18n.t("departments.detail_blankslate.managed_description"))
    end
  end
end
