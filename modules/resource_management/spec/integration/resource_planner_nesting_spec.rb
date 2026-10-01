# frozen_string_literal: true

require "spec_helper"

RSpec.describe "ResourcePlanner nesting", type: :model do
  let(:project) { create(:project, enabled_module_names: %w[resource_management]) }
  let(:owner) { create(:user, member_with_permissions: { project => %i[view_resource_planners] }) }
  let(:planner) { ResourcePlanner.create!(name: "Planner", project:, principal: owner) }

  describe "ResourceUserCard" do
    it "is allowed as a child of a ResourcePlanner" do
      card = ResourceUserCard.new(name: "Members", parent: planner)

      expect(card).to be_valid
    end
  end
end
