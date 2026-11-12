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

RSpec.describe Backlogs::SprintReports::Widgets::EpicProgress::Card do
  describe "component", type: :component do
    shared_let(:epic_type) { create(:type, name: "Epic") }
    shared_let(:task_type) { create(:type_task) }
    shared_let(:done_status) { create(:status) }
    shared_let(:open_status) { create(:status) }
    shared_let(:closed_status) { create(:closed_status) }

    let(:project) { create(:project, types: [epic_type, task_type].compact) }
    let(:user) { create(:user, member_with_permissions: { project => %i[view_work_packages] }) }
    let(:sprint) { create(:sprint, project:) }
    let!(:epic) { create_epic }

    current_user { user }

    subject(:rendered_component) { render_inline(described_class.new(epic:, sprint:, project:)) }

    def create_epic(*traits, project: self.project, **attributes)
      create(:work_package, *traits, type: epic_type, project:, **attributes)
    end

    def create_task(*traits, project: self.project, **attributes)
      create(:work_package, *traits, type: task_type, project:, **attributes)
    end

    context "when the project uses a named variant of the Epic type" do
      let!(:epic_variant) { create(:type_variant, type: epic_type, variant_name: "Business Epic") }
      let(:project) { create(:project, types: [epic_variant, task_type].compact) }

      it "still displays it as 'Epic', not the variant's own name" do
        expect(rendered_component).to have_css(".op-wp-info-line--type", exact_text: "EPIC")
      end
    end

    context "when computing progress counts" do
      before do
        project.done_status_ids = [done_status.id]
        create_task(parent: epic, status: done_status)
        create_task(parent: epic, status: open_status)
      end

      it "counts every descendant of the epic" do
        expect(rendered_component).to have_text("1 / 2 work packages")
        expect(rendered_component).to have_text("(50%)")
        expect(rendered_component).to have_css("[role='progressbar'][aria-valuenow='50'][aria-valuemin='0'][aria-valuemax='100']")
        expect(rendered_component).to have_css("[aria-label='#{epic.subject}: 1 of 2 work packages completed']")
      end
    end

    context "when the resolved ratio is not a whole percentage" do
      before do
        project.done_status_ids = [done_status.id]
        create_task(parent: epic, status: done_status)
        create_task(parent: epic, status: done_status)
        create_task(parent: epic, status: open_status)
      end

      it "rounds the percentage down" do
        expect(rendered_component).to have_text("(66%)")
      end
    end

    context "when a descendant has a globally closed status the project has not added to done_status_ids" do
      before do
        project.done_status_ids = []
        create_task(parent: epic, status: closed_status)
        create_task(parent: epic, status: open_status)
      end

      it "counts it as resolved" do
        expect(rendered_component).to have_text("1 / 2 work packages")
        expect(rendered_component).to have_text("(50%)")
      end
    end

    context "when a descendant belongs to a project with different done statuses" do
      let(:status) { create(:status) }
      let(:other_project) { create(:project, types: [task_type]) }
      let(:user) do
        create(:user, member_with_permissions: {
                 project => %i[view_work_packages],
                 other_project => %i[view_work_packages]
               })
      end

      before do
        create_task(parent: epic, status:)
        create_task(project: other_project, parent: epic, status:)
      end

      context "when only the descendant's project considers the status done" do
        before do
          project.done_status_ids = []
          other_project.done_status_ids = [status.id]
        end

        it "does not count either descendant as resolved" do
          expect(rendered_component).to have_text("0 / 2 work packages")
        end
      end

      context "when only the sprint's project considers the status done" do
        before do
          project.done_status_ids = [status.id]
          other_project.done_status_ids = []
        end

        it "counts both descendants as resolved" do
          expect(rendered_component).to have_text("2 / 2 work packages")
        end
      end
    end

    context "when descendant type is excluded from backlogs" do
      let(:excluded_type) { create(:type_bug) }
      let(:project) { create(:project, types: [epic_type, task_type, excluded_type].compact) }

      before do
        project.backlog_excluded_type_ids = [excluded_type.id]
        create(:work_package, type: excluded_type, project:, parent: epic)
      end

      it "includes it into the count" do
        expect(rendered_component).to have_text("0 / 1 work package")
      end
    end

    context "when a descendant is invisible to the user" do
      let(:other_project) { create(:project, types: [task_type]) }

      before do
        create_task(parent: epic)
        create_task(project: other_project, parent: epic)
      end

      it "excludes it from the count" do
        expect(rendered_component).to have_text("0 / 1 work package")
      end
    end

    context "when a visible descendant sits below an invisible one" do
      let(:other_project) { create(:project, types: [task_type]) }

      before do
        invisible_feature = create_task(project: other_project, parent: epic)
        create_task(parent: invisible_feature)
      end

      it "counts the visible descendant only" do
        expect(rendered_component).to have_text("0 / 1 work package")
      end
    end

    context "when the epic contains sub-epics" do
      before do
        create_task(parent: epic)
        direct_sub_epic = create_epic(parent: epic)
        create_task(parent: direct_sub_epic)
        feature = create_task(parent: epic)
        nested_sub_epic = create_epic(parent: feature)
        create_task(parent: nested_sub_epic)
      end

      it "counts the sub-epics, but not the work below them" do
        expect(rendered_component).to have_text("0 / 4 work packages")
      end
    end

    context "when the sprint is completed" do
      let(:before_completion) { 3.days.ago }
      let(:completed_at) { 2.days.ago }
      let(:after_completion) { 1.day.ago }
      let(:sprint) { create(:sprint, :completed, project:, completed_at:) }

      let!(:epic) { create_epic(:created_in_past, created_at: before_completion - 1.day) }

      context "when computing progress counts" do
        before do
          project.done_status_ids = [done_status.id]
          create_task(:created_in_past, parent: epic, status: done_status, created_at: before_completion)
        end

        context "when a descendant has since been moved out of the epic" do
          before do
            create_task(parent: nil,
                        journals: {
                          before_completion => { parent_id: epic.id },
                          after_completion => { parent_id: nil }
                        })
          end

          it "still counts it" do
            expect(rendered_component).to have_text("1 / 2 work packages")
            expect(rendered_component).to have_text("(50%)")
          end
        end

        context "when a descendant only joined the epic after completion" do
          before do
            create_task(parent: epic,
                        journals: {
                          before_completion => { parent_id: nil },
                          after_completion => { parent_id: epic.id }
                        })
          end

          it "does not count it, even though it is a descendant right now" do
            expect(rendered_component).to have_text("1 / 1 work package")
            expect(rendered_component).to have_text("(100%)")
          end
        end
      end

      context "when a visible descendant sits below an invisible one" do
        let(:other_project) { create(:project, types: [task_type]) }

        before do
          invisible_feature = create_task(:created_in_past, project: other_project, parent: epic,
                                                            created_at: before_completion)
          create_task(:created_in_past, parent: invisible_feature, created_at: before_completion)
        end

        it "counts the visible descendant only" do
          expect(rendered_component).to have_text("0 / 1 work package")
        end
      end

      context "when the epic contains sub-epics" do
        before do
          create_task(:created_in_past, parent: epic, created_at: before_completion)
          direct_sub_epic = create_epic(:created_in_past, parent: epic, created_at: before_completion)
          create_task(:created_in_past, parent: direct_sub_epic, created_at: before_completion)
          feature = create_task(:created_in_past, parent: epic, created_at: before_completion)
          nested_sub_epic = create_epic(:created_in_past, parent: feature, created_at: before_completion)
          create_task(:created_in_past, parent: nested_sub_epic, created_at: before_completion)
        end

        it "counts the sub-epics, but not the work below them" do
          expect(rendered_component).to have_text("0 / 4 work packages")
        end
      end

      context "with the estimation unit feature active", with_flag: { project_settings_estimation_unit: true } do
        before do
          project.estimation_unit = estimation_unit
          project.done_status_ids = [done_status.id]
          create_task(parent: epic, status: open_status, story_points: 30, estimated_hours: 30,
                      journals: {
                        before_completion => { status_id: done_status.id, story_points: 3, estimated_hours: 1.25 },
                        after_completion => {}
                      })
          create_task(:created_in_past, parent: epic, status: open_status, story_points: 4, estimated_hours: 4.5,
                                        created_at: before_completion)
          sub_epic = create_epic(:created_in_past, parent: epic, status: open_status, story_points: 1, estimated_hours: 1.75,
                                                   created_at: before_completion)
          create_task(:created_in_past, parent: sub_epic, status: open_status, story_points: 100, estimated_hours: 100,
                                        created_at: before_completion)
        end

        context "when estimation unit is story points" do
          let(:estimation_unit) { "story_points" }

          it "sums the story points at completion, but not the ones below sub-epics" do
            expect(rendered_component).to have_text("3 / 8 story points")
            expect(rendered_component).to have_text("(37%)")
            expect(rendered_component).to have_css("[role='progressbar'][aria-valuenow='37']")
            expect(rendered_component).to have_css("[aria-label='#{epic.subject}: 3 of 8 story points completed']")
          end
        end

        context "when estimation unit is time" do
          let(:estimation_unit) { "time" }

          it "sums the estimated time at completion, but not the one below sub-epics" do
            expect(rendered_component).to have_text("1.25h / 7.5h")
            expect(rendered_component).to have_text("(16%)")
            expect(rendered_component).to have_css("[role='progressbar'][aria-valuenow='16']")
            expect(rendered_component).to have_css("[aria-label='#{epic.subject}: 1.25h of 7.5h completed']")
          end
        end

        context "when estimation unit is none" do
          let(:estimation_unit) { "none" }

          it "counts the work packages at completion, but not the one below sub-epics" do
            expect(rendered_component).to have_text("1 / 3 work packages")
            expect(rendered_component).to have_text("(33%)")
            expect(rendered_component).to have_css("[role='progressbar'][aria-valuenow='33']")
            expect(rendered_component).to have_css("[aria-label='#{epic.subject}: 1 of 3 work packages completed']")
          end
        end
      end
    end

    context "with the estimation unit feature active", with_flag: { project_settings_estimation_unit: true } do
      before do
        project.estimation_unit = estimation_unit
        project.done_status_ids = [done_status.id]
        create_task(parent: epic, status: done_status, story_points: 3, estimated_hours: 1.25)
        create_task(parent: epic, status: open_status, story_points: 4, estimated_hours: 4.5)
        sub_epic = create_epic(parent: epic, status: open_status, story_points: 1, estimated_hours: 1.75)
        create_task(parent: sub_epic, status: open_status, story_points: 100, estimated_hours: 100)
      end

      context "when estimation unit is story points" do
        let(:estimation_unit) { "story_points" }

        it "sums the story points, but not the ones below sub-epics" do
          expect(rendered_component).to have_text("3 / 8 story points")
          expect(rendered_component).to have_text("(37%)")
          expect(rendered_component).to have_css("[role='progressbar'][aria-valuenow='37']")
          expect(rendered_component).to have_css("[aria-label='#{epic.subject}: 3 of 8 story points completed']")
        end
      end

      context "when estimation unit is time" do
        let(:estimation_unit) { "time" }

        it "sums the estimated time, but not the one below sub-epics" do
          expect(rendered_component).to have_text("1.25h / 7.5h")
          expect(rendered_component).to have_text("(16%)")
          expect(rendered_component).to have_css("[role='progressbar'][aria-valuenow='16']")
          expect(rendered_component).to have_css("[aria-label='#{epic.subject}: 1.25h of 7.5h completed']")
        end
      end

      context "when estimation unit is none" do
        let(:estimation_unit) { "none" }

        it "counts the work packages, but not the one below sub-epics" do
          expect(rendered_component).to have_text("1 / 3 work packages")
          expect(rendered_component).to have_text("(33%)")
          expect(rendered_component).to have_css("[role='progressbar'][aria-valuenow='33']")
          expect(rendered_component).to have_css("[aria-label='#{epic.subject}: 1 of 3 work packages completed']")
        end
      end
    end
  end
end
