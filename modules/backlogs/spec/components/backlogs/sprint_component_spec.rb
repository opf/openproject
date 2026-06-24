# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "rails_helper"

RSpec.describe Backlogs::SprintComponent, type: :component do
  include Rails.application.routes.url_helpers

  shared_let(:type_feature) { create(:type_feature) }
  shared_let(:type_task) { create(:type_task) }
  shared_let(:default_status) { create(:default_status) }
  shared_let(:default_priority) { create(:default_priority) }
  shared_let(:user) { create(:admin) }
  current_user { user }

  let(:project) { create(:project, types: [type_feature, type_task]) }
  let(:sprint) do
    create(:sprint, project:, name: "Sprint 1",
                    start_date: Date.yesterday, finish_date: Date.tomorrow)
  end

  subject(:rendered_component) do
    render_inline(described_class.new(sprint:, project:, current_user: user))
  end

  def menu_items
    page.all(:role, :menuitem).map { it.text.squish }
  end

  describe "rendering" do
    context "with work packages" do
      let!(:work_package1) do
        create(:work_package, project:, type: type_feature, status: default_status,
                              priority: default_priority, story_points: 5, position: 1, sprint:)
      end
      let!(:work_package2) do
        create(:work_package, project:, type: type_feature, status: default_status,
                              priority: default_priority, story_points: 3, position: 2, sprint:)
      end

      it_behaves_like "rendering Box", row_count: 2, header: true, footer: false

      it "renders a Primer::Beta::BorderBox with the sprint id" do
        expect(rendered_component).to have_css(".Box#sprint_#{sprint.id}")
      end

      it "renders the sprint title in the header" do
        expect(rendered_component).to have_heading "Sprint 1", level: 4
        expect(rendered_component).to have_css("h4.f4", text: "Sprint 1")
      end

      it "renders the story points total in the header description" do
        expect(rendered_component).to have_text("8 points", normalize_ws: true)
      end

      it "renders the inferred work-package count in the header" do
        expect(rendered_component).to have_css(
          ".Counter",
          text: "2",
          aria: { label: I18n.t(:label_x_work_packages, count: 2), live: "polite" }
        )
      end

      it "renders story points on each work package card" do
        expect(rendered_component).to have_css("span", text: "5", aria: { hidden: true })
        expect(rendered_component).to have_css(".sr-only", text: "5 story points")
        expect(rendered_component).to have_css("span", text: "3", aria: { hidden: true })
        expect(rendered_component).to have_css(".sr-only", text: "3 story points")
      end

      it "renders one Box-row per work package" do
        expect(rendered_component).to have_css(".Box-row", count: 2)
        expect(rendered_component).to have_text(work_package1.subject)
        expect(rendered_component).to have_text(work_package2.subject)
      end

      it "wires drop-target data attributes for the sprint" do
        expect(rendered_component).to have_css(".Box") do |box|
          expect(box["data-generic-drag-and-drop-target"]).to eq("container")
          expect(box["data-target-container-accessor"]).to eq(":scope > ul")
          expect(box["data-target-id"]).to eq("sprint:#{sprint.id}")
          expect(box["data-target-allowed-drag-type"]).to eq("story")
        end
      end

      it "passes an explicit sprint test selector to the shared box" do
        expect(rendered_component).to have_css(".Box[data-test-selector='sprint-#{sprint.id}']")
      end

      it "wires draggable data on work package rows" do
        expect(rendered_component).to have_css(".Box-row#work_package_#{work_package1.id}") do |row|
          expect(row["data-draggable-id"]).to eq(work_package1.id.to_s)
          expect(row["data-draggable-type"]).to eq("story")
          expect(row["data-backlogs--story-display-id-value"]).to eq(work_package1.display_id.to_s)
          expect(row["data-drop-url"])
            .to end_with(move_project_backlogs_work_package_path(project, work_package1))
        end
      end

      context "when params[:all] is true" do
        before do
          vc_test_controller.params[:all] = "1"
        end

        it "propagates ?all=true to the work package drop URL" do
          expect(rendered_component).to have_css(".Box-row#work_package_#{work_package1.id}") do |row|
            expect(row["data-drop-url"])
              .to eq(move_project_backlogs_work_package_path(project, work_package1, all: true))
          end
        end
      end

      it "renders the sprint kebab menu in the header" do
        expect(rendered_component).to have_element :"action-menu"
      end
    end

    context "when the user lacks the manage_sprint_items permission" do
      let(:role) { create(:project_role, permissions: %i[view_sprints view_work_packages]) }
      let(:user) { create(:user, member_with_roles: { project => role }) }
      let!(:work_package1) do
        create(:work_package, project:, type: type_feature, status: default_status,
                              priority: default_priority, story_points: 5, position: 1, sprint:)
      end

      it "does not mark work package rows as draggable" do
        expect(rendered_component).to have_css(".Box-row#work_package_#{work_package1.id}")
        expect(rendered_component).to have_no_css(".Box-row#work_package_#{work_package1.id}.Box-row--draggable")
        expect(rendered_component).to have_no_css(".Box-row#work_package_#{work_package1.id}[data-draggable-id]")
        expect(rendered_component).to have_no_css(".Box-row#work_package_#{work_package1.id}[data-drop-url]")
      end
    end

    context "without work packages" do
      it_behaves_like "rendering Box", row_count: 1, header: true, footer: false
      it_behaves_like "rendering Blank Slate", heading: "Sprint 1 is empty"

      it "renders the empty-state blankslate" do
        expect(rendered_component).to have_text("Sprint 1 is empty")
      end
    end

    describe "sprint status badge in header description" do
      context "when the sprint is in planning" do
        let(:sprint) do
          create(:sprint, project:, name: "Sprint 1",
                          start_date: Date.tomorrow, finish_date: Date.tomorrow + 7,
                          status: "in_planning")
        end

        it "renders the status badge" do
          expect(rendered_component).to have_css(".Label", text: "In planning")
        end
      end

      context "when the sprint is active" do
        let(:sprint) do
          create(:sprint, project:, name: "Sprint 1",
                          start_date: Date.yesterday, finish_date: Date.tomorrow,
                          status: "active")
        end

        it "renders the status badge" do
          expect(rendered_component).to have_css(".Label", text: "Active")
        end
      end

      context "when the sprint is completed" do
        let(:sprint) do
          create(:sprint, project:, name: "Sprint 1",
                          start_date: 2.weeks.ago, finish_date: 1.week.ago,
                          status: "completed")
        end

        it "renders the status badge" do
          expect(rendered_component).to have_css(".Label", text: "Completed")
        end
      end
    end

    describe "edit menu visibility for shared sprints" do
      let(:source_project) { create(:project, sprint_sharing: "share_all_projects", types: [type_feature, type_task]) }
      let(:project) { create(:project, sprint_sharing: "receive_shared", types: [type_feature, type_task]) }
      let(:sprint) do
        create(:sprint, project: source_project, name: "Shared Sprint",
                        start_date: Date.yesterday, finish_date: Date.tomorrow)
      end

      context "when user has create_sprints only in the defining project" do
        let(:user) do
          create(:user,
                 member_with_roles: {
                   project => create(:project_role, permissions: %i[view_sprints view_work_packages]),
                   source_project => create(:project_role, permissions: %i[view_sprints create_sprints])
                 })
        end

        it "renders the edit sprint menu item" do
          expect(rendered_component).to have_text("Edit sprint")
        end
      end

      context "when user has create_sprints in neither project" do
        let(:user) do
          create(:user,
                 member_with_roles: {
                   project => create(:project_role, permissions: %i[view_sprints view_work_packages]),
                   source_project => create(:project_role, permissions: %i[view_sprints])
                 })
        end

        it "does not render the edit sprint menu item" do
          expect(rendered_component).to have_no_text("Edit sprint")
        end
      end
    end

    describe "sprint goal in header" do
      context "when the sprint has a goal for the project" do
        before do
          create(:sprint_goal, sprint:, project:, text: "Ship the reporting dashboard")
        end

        it "renders the goal text" do
          expect(rendered_component).to have_text("Ship the reporting dashboard")
        end

        it "describes the sprint heading with the goal text" do
          expect(rendered_component).to have_heading(
            "Sprint 1",
            level: 4,
            accessible_description: "Ship the reporting dashboard"
          )
        end
      end

      context "when the sprint has no goal for the project" do
        it "does not render goal text" do
          expect(rendered_component).to have_no_css("#sprint_#{sprint.id}_goal")
        end

        it "does not describe the sprint heading" do
          expect(rendered_component).to have_css("h4", text: "Sprint 1", aria: { describedby: nil })
        end
      end
    end

    describe "sprint actions in header" do
      context "when the sprint is in planning with date range set" do
        let(:sprint) do
          create(:sprint, project:, name: "Sprint 1",
                          start_date: Date.tomorrow, finish_date: Date.tomorrow + 7,
                          status: "in_planning")
        end

        it "renders the start-sprint link enabled" do
          expect(rendered_component).to have_link("Start sprint")
        end
      end

      context "when the sprint is in planning without start date" do
        let(:sprint) do
          create(:sprint, project:, name: "Sprint 1",
                          start_date: nil,
                          status: "in_planning")
        end

        it "renders the start-sprint button as disabled" do
          expect(rendered_component).to have_selector(:link_or_button, "Start sprint", aria: { disabled: true })
        end
      end

      context "when the sprint is active" do
        let(:sprint) do
          create(:sprint, project:, name: "Sprint 1",
                          start_date: Date.yesterday, finish_date: Date.tomorrow,
                          status: "active")
        end
        let!(:task_board) { create(:board_grid_with_query, project:, linked: sprint) }

        it "renders the complete-sprint link" do
          expect(rendered_component).to have_link("Complete sprint")
        end

        context "when params[:all] is true" do
          before do
            vc_test_controller.params[:all] = "1"
          end

          it "preserves ?all=true on the complete-sprint link" do
            expect(rendered_component).to have_link(
              "Complete sprint",
              href: finish_project_backlogs_sprint_path(project, sprint, all: true)
            )
          end
        end

        it "preserves the grouped sprint action-menu structure" do
          rendered_component

          expect(menu_items).to eq(["Edit sprint", "Add work package", "Sprint board", "Burndown chart"])
          # The three item groups are separated by presentation-only dividers.
          expect(page).to have_css("li[role='presentation']", count: 2)
        end
      end
    end
  end
end
