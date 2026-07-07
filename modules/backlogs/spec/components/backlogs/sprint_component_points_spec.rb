# frozen_string_literal: true

require "rails_helper"

# Specs for the Scrum Base-style additions to the sprint header:
# per-status-category point chips.
RSpec.describe Backlogs::SprintComponent, type: :component do
  include Rails.application.routes.url_helpers

  shared_let(:user) { create(:admin) }
  shared_let(:project) { create(:project) }

  shared_let(:todo_status) { create(:default_status) }
  shared_let(:in_progress_status) { create(:status) }
  shared_let(:done_status) { create(:closed_status) }

  shared_let(:sprint) { create(:sprint, project:) }

  shared_let(:wp_todo) { create(:work_package, project:, status: todo_status, sprint:, story_points: 1) }
  shared_let(:wp_in_progress) { create(:work_package, project:, status: in_progress_status, sprint:, story_points: 2) }
  shared_let(:wp_done) { create(:work_package, project:, status: done_status, sprint:, story_points: 4) }

  current_user { user }

  subject(:rendered_component) do
    render_inline(described_class.new(
                    sprint:,
                    project:,
                    work_packages: [wp_todo, wp_in_progress, wp_done],
                    current_user: user
                  ))
  end

  describe "status-category point chips" do
    it "shows To Do / In Progress / Done point totals by category", :aggregate_failures do
      rendered_component

      expect(page).to have_css(".op-scrum-base-sprint-points--chip.-todo", text: "1")
      expect(page).to have_css(".op-scrum-base-sprint-points--chip.-in-progress", text: "2")
      expect(page).to have_css(".op-scrum-base-sprint-points--chip.-done", text: "4")
    end
  end
end
