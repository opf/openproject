# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Backlogs::WorkPackages", :skip_csrf, type: :rails_request do
  shared_let(:user) { create(:admin) }
  shared_let(:project) do
    create(:project, enabled_module_names: %w[work_package_tracking backlogs])
  end
  shared_let(:work_package) { create(:work_package, project:, story_points: 1) }

  current_user { user }

  describe "PATCH estimate (inline story-point estimation)" do
    subject(:perform) do
      patch "/projects/#{project.identifier}/backlogs/work_packages/#{work_package.id}/estimate",
            headers: { "ACCEPT" => "text/vnd.turbo-stream.html" },
            params: { work_package: { story_points: 8 } }
    end

    it "updates the story points and responds with a turbo stream", :aggregate_failures do
      perform

      expect(response).to be_successful
      expect(work_package.reload.story_points).to eq(8)
    end

    context "when clearing the estimate" do
      subject(:perform) do
        patch "/projects/#{project.identifier}/backlogs/work_packages/#{work_package.id}/estimate",
              headers: { "ACCEPT" => "text/vnd.turbo-stream.html" },
              params: { work_package: { story_points: "" } }
      end

      it "removes the story points" do
        perform

        expect(work_package.reload.story_points).to be_nil
      end
    end
  end
end
