# frozen_string_literal: true

require_relative "../spec_helper"

RSpec.describe CostEntry, "#editable_by? with reassigned ownership" do
  include Cost::PluginSpecHelper

  let(:project) { create(:project_with_types) }
  let(:victim) { create(:user) }
  let(:acting_user) { create(:user) }
  let(:work_package) do
    create(:work_package, project:, author: victim, type: project.types.first)
  end
  let(:cost_entry) do
    create(:cost_entry, entity: work_package, project:, user: victim)
  end

  before do
    is_member(project, acting_user, [:edit_own_cost_entries])
  end

  it "is not editable after reassignment to the acting user within the same request" do
    cost_entry.user = acting_user

    expect(cost_entry.editable_by?(acting_user)).to be(false)
  end
end
