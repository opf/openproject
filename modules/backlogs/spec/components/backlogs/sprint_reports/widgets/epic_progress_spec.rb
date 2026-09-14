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

RSpec.describe Backlogs::SprintReports::Widgets::EpicProgress, type: :component, with_ee: %i[sprint_report_pro_widgets] do
  let!(:epic_type) { create(:type, name: "Epic") }
  let(:task_type) { create(:type_task) }
  let(:project) { create(:project, types: [epic_type, task_type].compact) }
  let(:user) { create(:user, member_with_permissions: { project => %i[view_sprints view_work_packages] }) }
  let(:sprint) { create(:sprint, project:) }

  current_user { user }

  subject(:rendered_component) { render_inline(described_class.new(sprint, project)) }

  context "when the user lacks the view_sprints permission" do
    let(:user) { create(:user, member_with_permissions: { project => %i[view_work_packages] }) }

    it "renders nothing" do
      expect(rendered_component.to_s).to be_empty
    end
  end

  context "when no work package type is named Epic" do
    let(:epic_type) { nil }

    it "renders nothing" do
      expect(rendered_component.to_s).to be_empty
    end
  end

  context "when the enterprise token does not allow the sprint report pro widgets", with_ee: [] do
    it "renders nothing" do
      expect(rendered_component.to_s).to be_empty
    end
  end

  context "when the sprint has no relevant epics" do
    it "still renders the widget, with no epic cards" do
      expect(rendered_component).to have_text("Epic progress")
      expect(rendered_component).to have_no_css(".op-work-package-card")
    end
  end

  context "when a work package in the sprint is itself an epic" do
    let!(:epic) { create(:work_package, type: epic_type, project:, sprint:) }

    it "shows that epic" do
      expect(rendered_component).to have_css(".op-work-package-card", text: epic.subject)
    end
  end

  context "when a work package in the sprint has an epic ancestor" do
    let!(:epic) { create(:work_package, type: epic_type, project:) }
    let!(:feature) { create(:work_package, type: task_type, project:, parent: epic) }
    let!(:story) { create(:work_package, type: task_type, project:, parent: feature, sprint:) }

    it "shows the epic ancestor, walking through intermediate non-epic ancestors" do
      expect(rendered_component).to have_css(".op-work-package-card", text: epic.subject)
      expect(rendered_component).to have_no_css(".op-work-package-card", text: feature.subject)
    end
  end

  context "when a work package epic ancestor belongs to a different project" do
    let(:other_project) { create(:project, types: [epic_type]) }
    let(:user) do
      create(:user, member_with_permissions: {
               project => %i[view_sprints view_work_packages],
               other_project => %i[view_work_packages]
             })
    end
    let!(:epic) { create(:work_package, type: epic_type, project: other_project) }
    let!(:story) { create(:work_package, type: task_type, project:, parent: epic, sprint:) }

    it "still shows the epic" do
      expect(rendered_component).to have_css(".op-work-package-card", text: epic.subject)
    end
  end

  context "when a work package belongs to a different project than the one the report is for" do
    let(:other_project) { create(:project, types: [task_type]) }
    let!(:epic) { create(:work_package, type: epic_type, project:) }
    let!(:other_project_story) { create(:work_package, type: task_type, project: other_project, parent: epic, sprint:) }

    it "does not count it, so the epic isn't relevant" do
      expect(rendered_component).to have_no_css(".op-work-package-card", text: epic.subject)
    end
  end

  context "when a work package belongs to a different sprint" do
    let(:other_sprint) { create(:sprint, project:) }
    let!(:epic) { create(:work_package, type: epic_type, project:) }
    let!(:other_sprint_story) { create(:work_package, type: task_type, project:, parent: epic, sprint: other_sprint) }

    it "does not count it, so the epic isn't relevant" do
      expect(rendered_component).to have_no_css(".op-work-package-card", text: epic.subject)
    end
  end

  context "when computing progress counts" do
    let(:done_status) { create(:status) }
    let(:open_status) { create(:status) }
    let!(:epic) { create(:work_package, type: epic_type, project:, sprint:) }
    let!(:done_child) { create(:work_package, type: task_type, project:, parent: epic, status: done_status) }
    let!(:open_child) { create(:work_package, type: task_type, project:, parent: epic, status: open_status) }

    before { project.done_status_ids = [done_status.id] }

    it "counts every descendant of the epic, not just the ones in the sprint" do
      expect(rendered_component).to have_text("1 / 2 work packages")
      expect(rendered_component).to have_text("(50%)")
    end
  end

  context "when descendant type is excluded from backlogs" do
    let(:excluded_type) { create(:type_bug) }
    let(:project) { create(:project, types: [epic_type, task_type, excluded_type].compact) }
    let!(:epic) { create(:work_package, type: epic_type, project:, sprint:) }
    let!(:excluded_child) { create(:work_package, type: excluded_type, project:, parent: epic) }

    before { project.backlog_excluded_type_ids = [excluded_type.id] }

    it "includes it into the count" do
      expect(rendered_component).to have_text("0 / 1 work packages")
    end
  end

  context "when a descendant is invisible to the user" do
    let(:other_project) { create(:project, types: [task_type]) }
    let!(:epic) { create(:work_package, type: epic_type, project:, sprint:) }
    let!(:visible_child) { create(:work_package, type: task_type, project:, parent: epic) }
    let!(:invisible_child) { create(:work_package, type: task_type, project: other_project, parent: epic) }

    it "excludes it from the count" do
      expect(rendered_component).to have_text("0 / 1 work packages")
    end
  end

  context "when the sprint is completed" do
    let(:before_completion) { 3.days.ago }
    let(:completed_at) { 2.days.ago }
    let(:after_completion) { 1.day.ago }
    let(:sprint) { create(:sprint, :completed, project:, completed_at:) }

    let!(:epic_a) do
      create(:work_package, :created_in_past, type: epic_type, project:, created_at: before_completion - 1.day)
    end

    context "when a work package was reparented to a different epic after completion" do
      let!(:epic_b) do
        create(:work_package, :created_in_past, type: epic_type, project:, created_at: before_completion - 1.day)
      end
      let!(:story) do
        create(:work_package,
               type: task_type, project:, sprint:, parent: epic_b,
               journals: {
                 before_completion => { parent_id: epic_a.id },
                 after_completion => { parent_id: epic_b.id }
               })
      end

      it "still attributes it to the epic it belonged to when the sprint completed" do
        expect(rendered_component).to have_text(epic_a.subject)
        expect(rendered_component).to have_no_text(epic_b.subject)
      end
    end

    context "when a work package that was in the sprint has since been deleted" do
      let!(:story) do
        create(:work_package, :created_in_past, type: task_type, project:, sprint:, parent: epic_a,
                                                created_at: before_completion)
      end

      before { story.destroy! }

      it "drops all record of it, even from this now-frozen report" do
        expect(rendered_component).to have_no_text(epic_a.subject)
      end
    end

    context "when computing progress counts" do
      let(:done_status) { create(:status) }

      let!(:done_child) do
        create(:work_package, :created_in_past, type: task_type, project:, sprint:, status: done_status,
                                                parent: epic_a, created_at: before_completion)
      end

      before { project.done_status_ids = [done_status.id] }

      context "when a descendant has since been moved out of the epic" do
        let!(:moved_out_child) do
          create(:work_package,
                 type: task_type, project:, parent: nil,
                 journals: {
                   before_completion => { parent_id: epic_a.id },
                   after_completion => { parent_id: nil }
                 })
        end

        it "still counts it, the same way historic_relevant_epic_ids still counts a reparented ancestor" do
          expect(rendered_component).to have_text("1 / 2 work packages")
          expect(rendered_component).to have_text("(50%)")
        end
      end

      context "when a descendant only joined the epic after completion" do
        let!(:moved_in_child) do
          create(:work_package,
                 type: task_type, project:, parent: epic_a,
                 journals: {
                   before_completion => { parent_id: nil },
                   after_completion => { parent_id: epic_a.id }
                 })
        end

        it "does not count it, even though it is a descendant right now" do
          expect(rendered_component).to have_text("1 / 1 work packages")
          expect(rendered_component).to have_text("(100%)")
        end
      end
    end
  end
end
