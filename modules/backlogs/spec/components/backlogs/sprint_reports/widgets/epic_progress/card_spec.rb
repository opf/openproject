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

RSpec.describe Backlogs::SprintReports::Widgets::EpicProgress::Card, type: :component do
  let!(:epic_type) { create(:type, name: "Epic") }
  let(:task_type) { create(:type_task) }
  let(:project) { create(:project, types: [epic_type, task_type].compact) }
  let(:user) { create(:user, member_with_permissions: { project => %i[view_work_packages] }) }
  let(:sprint) { create(:sprint, project:) }
  let!(:epic) { create(:work_package, type: epic_type, project:) }

  current_user { user }

  subject(:rendered_component) { render_inline(described_class.new(epic:, sprint:, project:)) }

  context "when the project uses a named variant of the Epic type" do
    let!(:epic_variant) { create(:type_variant, type: epic_type, variant_name: "Business Epic") }
    let(:project) { create(:project, types: [epic_variant, task_type].compact) }

    it "still displays it as 'Epic', not the variant's own name" do
      expect(rendered_component).to have_css(".op-wp-info-line--type", exact_text: "EPIC")
    end
  end

  context "when computing progress counts" do
    let(:done_status) { create(:status) }
    let(:open_status) { create(:status) }
    let!(:done_child) { create(:work_package, type: task_type, project:, parent: epic, status: done_status) }
    let!(:open_child) { create(:work_package, type: task_type, project:, parent: epic, status: open_status) }

    before { project.done_status_ids = [done_status.id] }

    it "counts every descendant of the epic" do
      expect(rendered_component).to have_text("1 / 2 work packages")
      expect(rendered_component).to have_text("(50%)")
    end

    it "exposes the ratio as an accessible progressbar" do
      expect(rendered_component).to have_css("[role='progressbar'][aria-valuenow='50'][aria-valuemin='0'][aria-valuemax='100']")
      expect(rendered_component).to have_css("[aria-label='#{epic.subject}: 1 of 2 work packages completed']")
    end
  end

  context "when descendant type is excluded from backlogs" do
    let(:excluded_type) { create(:type_bug) }
    let(:project) { create(:project, types: [epic_type, task_type, excluded_type].compact) }
    let!(:excluded_child) { create(:work_package, type: excluded_type, project:, parent: epic) }

    before { project.backlog_excluded_type_ids = [excluded_type.id] }

    it "includes it into the count" do
      expect(rendered_component).to have_text("0 / 1 work packages")
    end
  end

  context "when a descendant is invisible to the user" do
    let(:other_project) { create(:project, types: [task_type]) }
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

    let!(:epic) do
      create(:work_package, :created_in_past, type: epic_type, project:, created_at: before_completion - 1.day)
    end

    context "when computing progress counts" do
      let(:done_status) { create(:status) }

      let!(:done_child) do
        create(:work_package, :created_in_past, type: task_type, project:, status: done_status,
                                                parent: epic, created_at: before_completion)
      end

      before { project.done_status_ids = [done_status.id] }

      context "when a descendant has since been moved out of the epic" do
        let!(:moved_out_child) do
          create(:work_package,
                 type: task_type, project:, parent: nil,
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
        let!(:moved_in_child) do
          create(:work_package,
                 type: task_type, project:, parent: epic,
                 journals: {
                   before_completion => { parent_id: nil },
                   after_completion => { parent_id: epic.id }
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
