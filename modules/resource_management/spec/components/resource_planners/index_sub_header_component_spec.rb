# frozen_string_literal: true

require "rails_helper"

RSpec.describe ResourcePlanners::IndexSubHeaderComponent, type: :component do
  shared_let(:project) { create(:project, enabled_module_names: %w[resource_management]) }

  let(:current_user) { user }

  subject(:rendered) do
    login_as(current_user)
    render_inline(described_class.new(project:))
    page
  end

  context "when the user can view resource planners" do
    let(:user) do
      create(:user, member_with_permissions: { project => %i[view_resource_planners] })
    end

    it "renders the create button" do
      expect(rendered).to have_link(text: I18n.t("resource_management.label_resource_planner"))
    end
  end

  context "when the user lacks view_resource_planners" do
    let(:user) { create(:user) }

    it "hides the create button" do
      expect(rendered).to have_no_link(text: I18n.t("resource_management.label_resource_planner"))
    end
  end
end
