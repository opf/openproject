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

require "spec_helper"

RSpec.describe "Planner views", type: :rails_request, with_settings: { working_days: [1, 2, 3, 4, 5] } do
  let!(:task) { create(:type_task) }
  let!(:role) do
    create(:project_role, permissions: ProjectRole::PERMISSIONS_FOR_PROJECT_CREATOR + %i[view_work_packages])
  end
  let(:user) { create(:user) }
  let(:path) { planner_path }

  current_user { user }

  subject { get path }

  context "without the planner flag" do
    it "is not found" do
      subject

      expect(response).to have_http_status(:not_found)
      expect(Project.count).to eq(0)
    end
  end

  context "with the planner flag", with_flag: { planner: true } do
    around { |example| travel_to(Time.zone.parse("2026-10-06 08:00")) { example.run } }

    let(:meeting_project) { create(:project, enabled_module_names: %w[meetings work_package_tracking]) }
    let!(:meeting) do
      create(:meeting, project: meeting_project, title: "XWiki daily", duration: 0.25,
                       start_time: user.time_zone.parse("#{user.today} 09:30"))
    end
    let(:referenced) { create(:work_package, project: meeting_project, subject: "Show GitLab branches") }
    let!(:work_package) do
      create(:work_package, project: Planner::ProjectService.new(user).call.result, type: task,
                            subject: "Book train to the offsite", due_date: user.today)
    end
    let(:planned) { create(:work_package, project: meeting_project, subject: "Branch tracking via GitLab webhook") }
    let!(:planned_task) do
      create(:work_package, project: Planner::ProjectService.new(user).call.result, type: task,
                            subject: "##{planned.id}", due_date: user.today)
    end
    let!(:task_with_reference) do
      create(:work_package, project: Planner::ProjectService.new(user).call.result, type: task,
                            subject: "Write down questions on ##{referenced.id} for the sync", due_date: user.today)
    end

    before do
      create(:member, project: meeting_project, principal: user,
                      roles: [create(:project_role, permissions: %i[view_meetings view_work_packages])])
      create(:meeting_participant, meeting:, user:)
    end

    it "shows meetings with their project, kind and time" do
      subject

      expect(page).to have_test_selector("planner-meeting-morning", text: "XWiki daily")
      expect(page).to have_test_selector("planner-meeting-morning", text: meeting_project.name)
      expect(page).to have_test_selector("planner-meeting-morning", text: "One-time meeting")
      expect(page).to have_test_selector("planner-meeting-time", text: "09:30 AM - 09:45 AM")
    end

    it "shows the notes of to-dos as plain text" do
      WorkPackage.where.not(id: work_package.id).update_all(description: nil)
      WorkPackage.where(id: work_package.id).update_all(description: "**Window seat**, facing\n\nforward")

      subject

      expect(page).to have_test_selector("planner-task-notes", count: 1)
      expect(page.find("[data-test-selector='planner-task-morning']", text: "Book train to the offsite"))
        .to have_test_selector("planner-task-notes", exact_text: "Window seat, facing forward", normalize_ws: true)
    end

    it "describes planned work packages by type, id and status" do
      subject

      expect(page).to have_test_selector("planner-reference", text: "Show GitLab branches", count: 1)
      expect(page).to have_test_selector("planner-planned", text: "Branch tracking via GitLab webhook")
      expect(page).to have_css("a[target='_blank'][data-test-selector='planner-planned']")
      expect(page).to have_css("a[target='_blank'][data-test-selector='planner-reference']")
      expect(page.find("[data-test-selector='planner-planned-box']"))
        .to have_test_selector("planner-planned").and have_test_selector("planner-task-info")
      expect(page).to have_test_selector("planner-task-info", count: 1)
      expect(page).to have_test_selector("planner-task-info", text: planned.formatted_id)
      expect(page).to have_test_selector("planner-task-info", text: planned.status.name)
    end

    context "with a /meeting task" do
      let(:colleague) do
        create(:user, login: "sakura", member_with_permissions: { meeting_project => %i[view_meetings] })
      end
      let!(:meeting_task) do
        create(:work_package, project: Planner::ProjectService.new(user).call.result, type: task,
                              subject: "Set up a /meeting with @#{colleague.login} about wiki permissions",
                              due_date: user.today)
      end

      it "offers to create the meeting, prefilled" do
        subject

        link = page.find("[data-test-selector='planner-create-meeting']")
        expect(link[:href]).to include("title=Wiki+permissions").and include("participant_ids%5B%5D=#{colleague.id}")
        expect(link["data-controller"]).to eq("async-dialog")
      end
    end

    it "opens on Today" do
      subject

      expect(page).to have_css("turbo-frame#planner_sidemenu")
      expect(page).to have_test_selector("planner-today")
      expect(page).to have_test_selector("planner-task-morning", text: "Book train to the offsite")
      expect(page).to have_test_selector("planner-section-counts", text: "3 to-dos | 1 meeting")
      expect(page).to have_test_selector("planner-section-afternoon", text: "No entries")
    end

    it "lets to-dos be dragged between day parts" do
      subject

      expect(page).to have_css("[data-controller='sortable-lists'][data-test-selector='planner-today']")
      expect(page).to have_css("[data-controller='sortable-lists--list'][data-sortable-lists--list-id-value='evening']")
      item = "[data-controller='sortable-lists--item'][data-sortable-lists--item-id-value='#{work_package.id}']"
      expect(page).to have_css("#{item} .DragHandle")
      expect(page).to have_test_selector("planner-meeting-morning")
      expect(page).to have_no_css("[data-test-selector='planner-meeting-morning'] .DragHandle")
    end

    it "adds to-dos in every day part, and through a dialog from the header" do
      subject

      link = page.find_link("Add to-do", href: new_dialog_planner_tasks_path(view: :today, date: user.today, day_part: :morning),
                                         match: :first)
      expect(link["data-controller"]).to eq("async-dialog")
      expect(page).to have_no_link("Add work package")
      %w[morning afternoon evening].each do |day_part|
        link = page.find("[data-test-selector='planner-add-todo-#{day_part}']")
        expect(link[:href]).to eq(planner_path(adding: day_part))
        expect(link["data-turbo-stream"]).to eq("true")
      end
      expect(page).to have_no_css("[data-test-selector^='planner-todo-input-']")
    end

    describe "filtering" do
      it "shows all entries by default" do
        subject

        expect(page).to have_test_selector("planner-filter", text: "All entries")
        expect(page).to have_link("To-dos only", href: planner_path(filter: "todos"))
        expect(page).to have_test_selector("planner-meeting-morning")
        expect(page).to have_test_selector("planner-task-morning")
      end

      it "shows only meetings, and keeps the filter for later visits" do
        get planner_path(filter: "meetings")

        expect(page).to have_test_selector("planner-meeting-morning")
        expect(page).not_to have_test_selector("planner-task-morning")
        expect(page).to have_no_css("[data-test-selector^='planner-add-todo-']")
        expect(page).to have_test_selector("planner-section-counts", text: "1 meeting")

        get planner_view_path(:upcoming)

        expect(page).to have_test_selector("planner-filter", text: "Meetings only")
      end

      it "shows only to-dos" do
        get planner_path(filter: "todos")

        expect(page).not_to have_test_selector("planner-meeting-morning")
        expect(page).to have_test_selector("planner-task-morning", text: "Book train to the offsite")
      end
    end

    context "when adding to the afternoon" do
      let(:path) { planner_path(adding: :afternoon) }

      it "shows an input row above the Add to-do link" do
        subject

        expect(page).to have_css("[data-test-selector='planner-todo-input-afternoon'] input[autofocus]")
        expect(page).to have_field("task[day_part]", type: :hidden, with: "afternoon")
        expect(page).to have_test_selector("planner-add-todo-afternoon")
        expect(page).to have_link("Cancel", href: planner_path)
        expect(page).to have_test_selector("planner-todo-input-afternoon", count: 1)
      end

      it "refreshes the view in place when asked for a Turbo Stream" do
        get path, headers: { "Accept" => "text/vnd.turbo-stream.html" }

        expect(response.body).to include('turbo-stream action="replace" target="planner-today-component"')
        expect(response.body).to include("planner-todo-input-afternoon")
      end
    end

    context "on Upcoming" do
      let(:path) { planner_view_path(:upcoming) }

      before do
        work_package.update_columns(due_date: user.today + 1, start_date: user.today + 1)
        meeting.update_columns(start_time: meeting.start_time + 1.day)
      end

      it "lists the coming days" do
        subject

        expect(page).to have_test_selector("planner-upcoming")
        expect(page).to have_test_selector("planner-upcoming-day", count: 7)
        expect(page).to have_test_selector("planner-upcoming-day", text: "Tomorrow")
        expect(page).to have_test_selector("planner-upcoming-day", text: /Saturday 10th\s+Non-working day/)
        expect(page).to have_test_selector("planner-upcoming-task", text: "Book train to the offsite")
        expect(page).to have_test_selector("planner-upcoming-meeting", text: "One-time meeting")
      end
    end

    context "on Overdue" do
      let(:path) { planner_view_path(:overdue) }

      before { work_package.update_columns(due_date: nil, start_date: nil) }

      it "shows tasks left over or without a date" do
        subject

        expect(page).to have_test_selector("planner-overdue")
        expect(page).to have_test_selector("planner-overdue-task", text: "Book train to the offsite")
      end
    end

    context "on Completed" do
      let(:path) { planner_view_path(:completed) }

      before { work_package.update_columns(status_id: create(:closed_status).id, updated_at: 1.day.ago) }

      it "shows the tasks completed in the last days, by day" do
        subject

        expect(page).to have_test_selector("planner-completed-day", text: "Yesterday")
        expect(page).to have_test_selector("planner-completed-task", text: "Book train to the offsite")
      end
    end

    describe "the menu" do
      before { work_package.update_columns(due_date: nil, start_date: nil) }

      it "lists the views and counts the overdue tasks" do
        get planner_menu_path(current_href: planner_view_path(:overdue))

        expect(page).to have_link("Today", href: planner_path)
        expect(page).to have_link("Upcoming", href: planner_view_path(:upcoming))
        expect(page).to have_link("Completed", href: planner_view_path(:completed))
        expect(page).to have_test_selector("op-submenu--item-count", text: "1")
      end
    end
  end
end
