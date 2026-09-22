# frozen_string_literal: true

require "spec_helper"

module PlannerRoutesCases
  # Arguments per helper, resolved against whichever scope is under test. The extra
  # keywords on the timeline and user-allocation entries are deliberate: a positional
  # argument combined with any other keyword drops Rails out of optimized generation,
  # and the positional then binds to the optional project_id.
  PLANNER_FIRST = {
    planner_path: ->(pl, _v) { [pl] },
    edit_planner_path: ->(pl, _v) { [pl] },
    toggle_public_planner_path: ->(pl, _v) { [pl] },
    planner_views_path: ->(pl, _v) { [pl] },
    new_planner_view_path: ->(pl, _v) { [pl] },
    planner_view_path: ->(pl, v) { [pl, v] },
    edit_planner_view_path: ->(pl, v) { [pl, v] },
    new_planner_view_user_path: ->(pl, v) { [pl, v] },
    planner_view_users_path: ->(pl, v) { [pl, v] },
    remove_planner_view_user_path: ->(pl, v) { [pl, v, 42] },
    new_planner_view_work_package_path: ->(pl, v) { [pl, v] },
    planner_view_work_packages_path: ->(pl, v) { [pl, v] },
    move_planner_view_work_package_path: ->(pl, v) { [pl, v, 7, { direction: "down" }] },
    reorder_planner_view_work_package_path: ->(pl, v) { [pl, v, 7] },
    remove_planner_view_work_package_path: ->(pl, v) { [pl, v, 7] },
    edit_planner_view_work_package_progress_path: ->(pl, v) { [pl, v, WorkPackage.new(id: 7)] },
    planner_view_work_package_progress_path: ->(pl, v) { [pl, v, WorkPackage.new(id: 7)] },
    planner_view_work_package_timeline_resources_path: ->(pl, v) { [pl, v, { format: :json }] },
    planner_view_work_package_timeline_events_path: ->(pl, v) { [pl, v, { format: :json }] },
    planner_view_user_timeline_resources_path: ->(pl, v) { [pl, v, { format: :json }] },
    planner_view_user_timeline_events_path: ->(pl, v) { [pl, v, { format: :json }] }
  }.freeze

  PROJECT_FIRST = {
    planners_path: ->(pr, _ctx) { [pr] },
    new_planner_path: ->(pr, _ctx) { [pr] },
    menu_planners_path: ->(pr, _ctx) { [pr] },
    staffing_path: ->(pr, _ctx) { [pr] },
    staffing_assign_path: ->(pr, ctx) { [pr, ctx[:allocation]] },
    allocations_path: ->(pr, _ctx) { [pr] },
    new_allocation_path: ->(pr, _ctx) { [pr] },
    allocation_path: ->(pr, ctx) { [pr, ctx[:allocation]] },
    edit_allocation_path: ->(pr, ctx) { [pr, ctx[:allocation]] },
    refresh_form_allocations_path: ->(pr, _ctx) { [pr] },
    work_package_allocations_path: ->(pr, ctx) { [pr, ctx[:work_package]] },
    user_allocations_path: ->(pr, ctx) { [pr, ctx[:user], { resource_planner_view_id: 7 }] }
  }.freeze
end

RSpec.describe ResourceManagement::PlannerRoutes do
  subject(:routes) { Class.new { include ResourceManagement::PlannerRoutes }.new }

  shared_let(:project) do
    create(:project, identifier: "planner-routes", enabled_module_names: %w[resource_management work_package_tracking])
  end
  shared_let(:user) { create(:user) }
  shared_let(:work_package) { create(:work_package, project:) }
  shared_let(:allocation) { create(:resource_allocation, entity: work_package) }

  shared_let(:global_planner) { create(:resource_planner, :global) }
  shared_let(:project_planner) { create(:resource_planner, project:) }
  shared_let(:global_view) { create(:resource_user_card, parent: global_planner, project: nil) }
  shared_let(:project_view) { create(:resource_user_card, parent: project_planner, project:) }

  def fixtures = { allocation:, work_package:, user: }

  def call(helper, args)
    positional = args.last.is_a?(Hash) ? args[0..-2] : args
    keywords = args.last.is_a?(Hash) ? args.last : {}
    routes.public_send(helper, *positional, **keywords)
  end

  it "covers every helper the module exposes" do
    expect((PlannerRoutesCases::PLANNER_FIRST.keys + PlannerRoutesCases::PROJECT_FIRST.keys).sort)
      .to match_array(described_class.public_instance_methods(false).sort)
  end

  PlannerRoutesCases::PLANNER_FIRST.each_key do |helper|
    describe "##{helper}" do
      it "addresses a global planner without naming a project" do
        path = call(helper, PlannerRoutesCases::PLANNER_FIRST[helper].call(global_planner, global_view))

        expect(path).to start_with("/resource_planners/#{global_planner.id}")
      end

      it "names the project of a project planner" do
        path = call(helper, PlannerRoutesCases::PLANNER_FIRST[helper].call(project_planner, project_view))

        expect(path).to start_with("/projects/planner-routes/resource_planners/#{project_planner.id}")
      end
    end
  end

  PlannerRoutesCases::PROJECT_FIRST.each_key do |helper|
    describe "##{helper}" do
      it "omits the project segment when there is none" do
        path = call(helper, PlannerRoutesCases::PROJECT_FIRST[helper].call(nil, fixtures))

        expect(path).not_to start_with("/projects/")
      end

      it "names the project when there is one" do
        path = call(helper, PlannerRoutesCases::PROJECT_FIRST[helper].call(project, fixtures))

        expect(path).to start_with("/projects/planner-routes/")
      end
    end
  end
end
