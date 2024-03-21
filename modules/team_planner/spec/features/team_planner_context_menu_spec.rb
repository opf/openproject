require "spec_helper"
require_relative "shared_context"
require "features/work_packages/table/context_menu/context_menu_shared_examples"

RSpec.describe "Work package table context menu",
               :js,
               with_ee: %i[team_planner_view],
               with_settings: { start_of_week: 1 } do
  include_context "with team planner full access"

  let!(:work_package) do
    create(:work_package,
           project:,
           assigned_to: user,
           start_date: Time.zone.today.beginning_of_week.next_occurring(:tuesday),
           due_date: Time.zone.today.beginning_of_week.next_occurring(:thursday))
  end
  let(:menu) { Components::WorkPackages::ContextMenu.new }

  shared_let(:user) do
    create(:admin,
           member_with_permissions: { project => %w[
             view_work_packages edit_work_packages add_work_packages
             view_team_planner manage_team_planner
             save_queries manage_public_queries
             work_package_assigned
           ] })
  end

  before do
    login_as user
    team_planner.visit!

    team_planner.add_assignee user
    team_planner.within_lane(user) do
      team_planner.expect_event work_package
    end
  end

  it_behaves_like "provides a single WP context menu" do
    let(:open_context_menu) do
      -> {
        team_planner.visit!
        loading_indicator_saveguard

        team_planner.add_assignee user

        team_planner.within_lane(user) do
          team_planner.expect_event work_package
        end

        # Open context menu
        menu.expect_closed
        menu.open_for(work_package, card_view: true)
      }
    end
  end
end
