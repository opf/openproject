# frozen_string_literal: true

require_relative "../../../spec_helper"

RSpec.describe Admin::Departments::MoveUserDialogComponent, type: :component do
  let(:user) { create(:user) }
  let(:managed) { create(:department, lastname: "Managed") }
  let(:manual) { create(:department, lastname: "Manual") }

  context "when the source department is managed by LDAP" do
    before { create(:ldap_synchronized_department, group: managed) }

    it "shows an info message and offers no move action" do
      render_inline(described_class.new(user:, from_department: managed.reload, to_department: manual))

      expect(page).to have_text(I18n.t("departments.move_user_dialog.managed_heading"))
      expect(page).to have_no_text(I18n.t("departments.move_user_dialog.confirm"))
    end
  end

  context "when the source department is not managed by LDAP" do
    it "offers to move the user" do
      render_inline(described_class.new(user:, from_department: manual, to_department: managed))

      expect(page).to have_text(I18n.t("departments.move_user_dialog.heading"))
      expect(page).to have_no_text(I18n.t("departments.move_user_dialog.managed_heading"))
    end
  end
end
