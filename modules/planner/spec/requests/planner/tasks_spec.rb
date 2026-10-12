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

RSpec.describe "Planner tasks", :skip_csrf, type: :rails_request do
  let!(:task_type) { create(:type_task) }
  let!(:status) { create(:default_status) }
  let!(:priority) { create(:default_priority) }
  let!(:closed_status) { create(:closed_status) }
  let!(:role) do
    create(:project_role,
           permissions: ProjectRole::PERMISSIONS_FOR_PROJECT_CREATOR +
             %i[view_work_packages add_work_packages edit_work_packages manage_work_package_relations])
  end
  let!(:workflow) { create(:status_transition, type: task_type, role:, old_status: status, new_status: closed_status) }
  let(:user) { create(:user) }
  let(:params) { { task: { subject: "Book train to the offsite", day_part: "evening" } } }

  current_user { user }

  subject { post planner_tasks_path, params: }

  context "with the planner flag", with_flag: { planner: true } do
    it "adds the task to Today and goes back to it" do
      expect { subject }.to change(WorkPackage, :count).by(1)
      expect(response).to redirect_to(planner_path)
      expect(response).to have_http_status(:see_other)

      follow_redirect!
      expect(page).to have_test_selector("planner-task-evening", text: "Book train to the offsite")
    end

    context "when adding on Upcoming" do
      let(:date) { user.today + 2 }
      let(:params) { { task: { subject: "Book train", date: date.iso8601 }, view: "upcoming", adding: date.iso8601 } }
      let(:headers) { { "Accept" => "text/vnd.turbo-stream.html" } }

      subject { post planner_tasks_path, params:, headers: }

      it "adds the task to that day and keeps the day's form open" do
        expect { subject }.to change(WorkPackage, :count).by(1)
        expect(WorkPackage.last.due_date).to eq(date)
        expect(response.body).to include('target="planner-upcoming-component"')
        expect(response.body[/<details[^>]*planner-add-todo-#{date.iso8601}"[^>]*>/]).to include("open")
      end
    end

    context "when adding on Overdue" do
      let(:params) { { task: { subject: "Someday", date: "" }, view: "overdue" } }

      it "adds an undated task" do
        expect { subject }.to change(WorkPackage, :count).by(1)
        expect(WorkPackage.last.due_date).to be_nil
        expect(response).to redirect_to(planner_view_path(:overdue))
      end
    end

    context "with a blank subject" do
      let(:params) { { task: { subject: "", day_part: "evening" } } }

      it "shows the error" do
        expect { subject }.not_to change(WorkPackage, :count)
        expect(flash[:error]).to be_present
      end
    end
  end

  describe "ticking a task off", with_flag: { planner: true } do
    let(:task) { Planner::CreateTaskService.new(user:).call(subject: "Book train", day_part: :evening).result }
    let(:headers) { { "Accept" => "text/vnd.turbo-stream.html" } }

    subject { patch planner_task_path(task), params: { done: true }, headers: }

    it "closes it and re-renders Today" do
      subject

      expect(task.reload.status).to eq(closed_status)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('turbo-stream action="replace" target="planner-today-component"')
    end

    context "with semantic identifiers", with_settings: { work_packages_identifier: "semantic" } do
      it "finds the task by its project-based id" do
        subject

        expect(planner_task_path(task)).to end_with("/#{task.display_id}")
        expect(task.display_id).to match(WorkPackage::SemanticIdentifier::SEMANTIC_ID_PATTERN)
        expect(task.reload.status).to eq(closed_status)
      end
    end

    context "for a work package outside My work" do
      let(:task) { create(:work_package) }

      it "is not found" do
        subject

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "moving tasks", with_flag: { planner: true } do
    let(:task) { Planner::CreateTaskService.new(user:).call(subject: "Book train", day_part: :morning).result }
    let(:headers) { { "Accept" => "text/vnd.turbo-stream.html" } }

    it "moves a task to another day part" do
      patch(plan_planner_task_path(task, to: :evening), headers:)

      expect(response).to have_http_status(:ok)
      expect(Planner::DayPartField.find.day_part_of(task.reload)).to eq(:evening)
    end

    it "plans a task dropped on another day part" do
      put(drop_planner_task_path(task), params: { list_type: "todo", list_id: "afternoon", prev_id: "" }, headers:)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('target="planner-today-component"')
      expect(Planner::DayPartField.find.day_part_of(task.reload)).to eq(:afternoon)
    end

    it "plans a task dropped on a day of Upcoming" do
      date = user.today + 3
      put(drop_planner_task_path(task, view: "upcoming"), params: { list_type: "todo", list_id: date.iso8601 }, headers:)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('target="planner-upcoming-component"')
      expect(task.reload.due_date).to eq(date)
    end

    context "when planning from Overdue" do
      let!(:left_over) do
        Planner::CreateTaskService.new(user:).call(subject: "Left over", day_part: :afternoon).result.tap do |task|
          task.update_columns(start_date: user.today - 3, due_date: user.today - 3)
        end
      end

      it "offers to plan it for today with one click" do
        get planner_view_path(:overdue)

        form = page.find("[data-test-selector='planner-plan-today']").ancestor("form")
        expect(form[:action]).to eq(plan_planner_task_path(left_over, to: :today, view: :overdue))
      end

      it "plans it for today and re-renders Overdue and the menu" do
        patch(plan_planner_task_path(left_over, to: :today, view: :overdue), headers:)

        expect(left_over.reload.due_date).to eq(user.today)
        expect(response.body).to include('target="planner-overdue-component"')
        expect(response.body).to include('target="planner_sidemenu"')
      end
    end
  end

  describe "adding a work package", with_flag: { planner: true } do
    let(:team_project) { create(:project) }
    let!(:work_package) { create(:work_package, project: team_project) }
    let(:headers) { { "Accept" => "text/vnd.turbo-stream.html" } }

    subject { post planner_work_package_path(work_package.display_id), headers: }

    context "when the user can see it" do
      before { create(:member, project: team_project, principal: user, roles: [role]) }

      it "plans it for today and confirms with a flash" do
        expect { subject }.to change(WorkPackage, :count).by(1)
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Added to")
      end
    end

    context "when the user cannot see it" do
      it "is not found" do
        expect { subject }.not_to change(WorkPackage, :count)
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  context "without the planner flag" do
    it "is not found" do
      subject

      expect(response).to have_http_status(:not_found)
    end
  end
end
