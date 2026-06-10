# frozen_string_literal: true

require "rails_helper"

RSpec.describe ResourcePlanners::RowComponent, type: :component do
  include Rails.application.routes.url_helpers

  shared_let(:project) { create(:project, enabled_module_names: %w[resource_management]) }
  shared_let(:owner) do
    create(:user, member_with_permissions: { project => %i[view_resource_planners] })
  end

  let(:public_planner) { false }
  let(:planner) { create(:resource_planner, project:, principal: owner, public: public_planner) }
  let(:current_user) { owner }

  let(:table) do
    ResourcePlanners::TableComponent.new(rows: [planner], current_project: project)
  end

  subject(:rendered) do
    render_inline(described_class.new(row: planner, table:))
    page
  end

  before { login_as(current_user) }

  describe "name column" do
    it "links to the planner's show page" do
      expect(rendered).to have_link(planner.name, href: project_resource_planner_path(project, planner))
    end

    context "when the planner is favorited by the current user" do
      before { planner.add_favoriting_user(current_user) }

      it "shows the filled-star indicator next to the name" do
        expect(rendered).to have_css("svg.octicon-star-fill.op-primer--star-icon")
      end
    end

    context "when the planner is not favorited" do
      it "does not show the filled-star indicator next to the name" do
        expect(rendered).to have_no_css("svg.octicon-star-fill.op-primer--star-icon")
      end
    end
  end

  describe "action menu" do
    it "always offers the favorite action" do
      expect(rendered).to have_link(text: I18n.t("resource_management.action.favorite"))
    end

    context "when the planner is already favorited" do
      before { planner.add_favoriting_user(current_user) }

      it "switches the favorite action to its unfavorite label" do
        expect(rendered).to have_link(text: I18n.t("resource_management.action.unfavorite"))
        expect(rendered).to have_no_link(text: I18n.t("resource_management.action.favorite"))
      end
    end

    describe "toggle public" do
      context "when the user lacks manage_public_resource_planners" do
        it "is hidden" do
          expect(rendered).to have_no_link(text: I18n.t("resource_management.action.make_public"))
          expect(rendered).to have_no_link(text: I18n.t("resource_management.action.make_private"))
        end
      end

      context "when the user has manage_public_resource_planners on a private planner" do
        let(:current_user) do
          create(:user, member_with_permissions: { project => %i[view_resource_planners manage_public_resource_planners] })
        end

        it "offers the make-public action" do
          expect(rendered).to have_link(text: I18n.t("resource_management.action.make_public"))
        end
      end

      context "when the user has manage_public_resource_planners on a public planner" do
        let(:public_planner) { true }
        let(:current_user) do
          create(:user, member_with_permissions: { project => %i[view_resource_planners manage_public_resource_planners] })
        end

        it "offers the make-private action" do
          expect(rendered).to have_link(text: I18n.t("resource_management.action.make_private"))
        end
      end
    end

    describe "delete" do
      context "when the current user owns the planner" do
        it "offers the delete action" do
          expect(rendered).to have_link(text: I18n.t("resource_management.action.delete"))
        end
      end

      context "when the current user is a non-owner viewer of a private planner" do
        let(:current_user) do
          create(:user, member_with_permissions: { project => %i[view_resource_planners] })
        end

        it "hides the delete action" do
          expect(rendered).to have_no_link(text: I18n.t("resource_management.action.delete"))
        end
      end

      context "when the planner is public and the current user can manage_public" do
        let(:public_planner) { true }
        let(:current_user) do
          create(:user, member_with_permissions: { project => %i[view_resource_planners manage_public_resource_planners] })
        end

        it "offers the delete action" do
          expect(rendered).to have_link(text: I18n.t("resource_management.action.delete"))
        end
      end

      context "when the current user is an admin" do
        let(:current_user) { create(:admin) }

        it "offers the delete action" do
          expect(rendered).to have_link(text: I18n.t("resource_management.action.delete"))
        end
      end
    end
  end
end
