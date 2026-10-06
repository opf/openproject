# frozen_string_literal: true

require "spec_helper"

RSpec.describe Search::SemanticResult do
  describe ".ids" do
    let(:user) { create(:user) }
    let(:project) { create(:project, members: { user => create(:project_role, permissions: [:view_work_packages]) }) }
    let!(:wp1) { create(:work_package, project:) }
    let!(:wp2) { create(:work_package, project:) }

    it "returns IDs of work packages visible to the user" do
      expect(described_class.ids("some query", user)).to include(wp1.id, wp2.id)
    end

    it "does not return IDs of work packages the user cannot see" do
      invisible_wp = create(:work_package)
      expect(described_class.ids("some query", user)).not_to include(invisible_wp.id)
    end

    it "returns at most 3 results" do
      create(:work_package, project:)
      create(:work_package, project:)
      expect(described_class.ids("some query", user).length).to be <= 3
    end
  end
end
