# frozen_string_literal: true

require "spec_helper"

RSpec.describe Projects::Settings::BacklogSharingsController do
  describe "routing" do
    it {
      expect(get("/projects/project_42/settings/backlog_sharing")).to route_to(
        controller: "projects/settings/backlog_sharings",
        action: "show",
        project_id: "project_42"
      )
    }

    it {
      expect(patch("/projects/project_42/settings/backlog_sharing")).to route_to(
        controller: "projects/settings/backlog_sharings",
        action: "update",
        project_id: "project_42"
      )
    }
  end
end
