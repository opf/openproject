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
             %i[view_work_packages add_work_packages edit_work_packages delete_work_packages
                manage_work_package_relations])
  end
  let!(:workflow) { create(:status_transition, type: task_type, role:, old_status: status, new_status: closed_status) }
  let(:user) { create(:user) }
  let(:planner_project) { Planner::ProjectService.new(user).call.result }
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

    describe "the Add to-do dialog" do
      let(:headers) { { "Accept" => "text/vnd.turbo-stream.html" } }

      it "starts with the given date and day part" do
        get(new_dialog_planner_tasks_path(view: :upcoming, date: "2026-10-20", day_part: :evening), headers:)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include(Planner::AddTodoDialogComponent::DIALOG_ID)
        expect(response.body).to include("2026-10-20")
        expect(response.body).to match(/name="task\[day_part\]"[^>]*value="evening"|value="evening"[^>]*name="task\[day_part\]"/)
        expect(response.body).to include('name="view"')
        expect(response.body).to include("augmented-text-area-description")
        expect(response.body).to include("data-in-dialog=\"&quot;#{Planner::AddTodoDialogComponent::DIALOG_ID}&quot;\"")
      end

      it "closes once the to-do is added" do
        post(planner_tasks_path,
             params: { task: { subject: "Book train", date: "2026-10-20", day_part: "evening", description: "Window seat" } },
             headers:)

        expect(WorkPackage.last).to have_attributes(due_date: Date.new(2026, 10, 20), description: "Window seat")
        expect(response.body).to include(%(action="closeDialog" target="#{Planner::AddTodoDialogComponent::DIALOG_ID}"))
      end
    end

    describe "a to-do about a work package" do
      let(:headers) { { "Accept" => "text/vnd.turbo-stream.html" } }
      let(:team_project) { create(:project) }
      let(:work_package) { create(:work_package, project: team_project, subject: "Contact sponsoring partners") }

      before do
        create(:member, project: team_project, principal: user,
                        roles: [create(:project_role, permissions: %i[view_work_packages manage_work_package_relations])])
      end

      it "offers to search open work packages outside My work, below the to-do's text" do
        get(new_dialog_planner_tasks_path(date: "2026-10-20", day_part: :evening), headers:)

        expect(response).to have_http_status(:ok)
        body = response.body
        expect(body.index('name="task[subject]"')).to be < body.index("planner-work-package-autocompleter")
        expect(body.index("planner-work-package-autocompleter")).to be < body.index("augmented-text-area-description")
        filters = JSON.parse(CGI.unescapeHTML(body[/data-filters="([^"]*)"/, 1]))
        my_work = Planner::ProjectService.new(user).call.result
        expect(filters).to contain_exactly({ "name" => "status", "operator" => "o", "values" => [] },
                                           { "name" => "project", "operator" => "!", "values" => [my_work.id.to_s] })
      end

      it "plans the picked work package itself when the to-do's text is left empty" do
        post(planner_tasks_path,
             params: { task: { subject: "", work_package_id: work_package.id, date: "2026-10-20", day_part: "evening" } },
             headers:)

        task = WorkPackage.last
        expect(task).to have_attributes(subject: "##{work_package.display_id}", due_date: Date.new(2026, 10, 20))
        expect(Planner::DayPartField.find.day_part_of(task)).to eq(:evening)
        expect(response.body).to include(%(action="closeDialog" target="#{Planner::AddTodoDialogComponent::DIALOG_ID}"))
        expect(response.body).to include("Added to Evening on")
      end

      it "references the picked work package in the to-do's text" do
        post(planner_tasks_path,
             params: { task: { subject: "Ask Maya", work_package_id: work_package.id, date: "2026-10-20" } },
             headers:)

        expect(WorkPackage.last.subject).to eq("Ask Maya ##{work_package.display_id}")
        expect(Relation.where(from: WorkPackage.last, to: work_package)).to exist
      end

      it "adds a plain to-do when no work package is picked" do
        post(planner_tasks_path, params: { task: { subject: "Book train", work_package_id: "", date: "2026-10-20" } }, headers:)

        expect(WorkPackage.last.subject).to eq("Book train")
        expect(response.body).to include(%(action="closeDialog" target="#{Planner::AddTodoDialogComponent::DIALOG_ID}"))
      end

      it "refuses a work package the user cannot see" do
        hidden = create(:work_package)

        expect do
          post(planner_tasks_path, params: { task: { work_package_id: hidden.id, date: "2026-10-20" } }, headers:)
        end.not_to change(WorkPackage, :count)
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include("Pick a work package you can see.")
      end
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
        expect(response.body).to include("planner-todo-input-#{date.iso8601}")
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
    let(:task) { Planner::CreateTaskService.new(user:, project: planner_project).call(subject: "Book train", day_part: :evening).result }
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
    let(:task) { Planner::CreateTaskService.new(user:, project: planner_project).call(subject: "Book train", day_part: :morning).result }
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

    it "re-renders Today for a view it does not know" do
      patch(plan_planner_task_path(task, to: :evening, view: "someday"), headers:)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('target="planner-today-component"')
    end

    context "when planning from Overdue" do
      let!(:left_over) do
        Planner::CreateTaskService
          .new(user:, project: planner_project)
          .call(subject: "Left over", day_part: :afternoon).result.tap do |task|
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

  describe "deleting a task", with_flag: { planner: true } do
    let!(:task) { Planner::CreateTaskService.new(user:, project: planner_project).call(subject: "Book train", day_part: :morning).result }
    let(:headers) { { "Accept" => "text/vnd.turbo-stream.html" } }

    it "offers it in the task menu, after a confirmation" do
      get planner_path

      form = page.find("[data-test-selector='planner-delete-task'] form", visible: :all)
      expect(form[:action]).to eq(planner_task_path(task))
      expect(form["data-turbo-confirm"]).to eq("Are you sure?")
      expect(form).to have_css("input[name='_method'][value='delete']", visible: :all)
    end

    context "when it plans a work package" do
      let(:team_project) { create(:project) }
      let(:work_package) { create(:work_package, project: team_project) }
      let!(:task) do
        create(:member, project: team_project, principal: user, roles: [role])
        Planner::AddWorkPackageService.new(user:, project: planner_project).call(work_package:).result
      end

      it "offers to remove it from My planner, keeping the work package" do
        get planner_path

        item = page.find("[data-test-selector='planner-delete-task']", visible: :all)
        expect(item.text(:all)).to include("Remove from My planner")
        expect(item.find("form", visible: :all)["data-turbo-confirm"]).to include("It stays in its project.")

        expect { delete(planner_task_path(task), headers:) }.to change(WorkPackage, :count).by(-1)
        expect(work_package.reload).to be_present
      end
    end

    it "deletes it and re-renders the view" do
      expect { delete(planner_task_path(task, view: :upcoming), headers:) }.to change(WorkPackage, :count).by(-1)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('target="planner-upcoming-component"')
    end

    context "for a work package outside My work" do
      let!(:other) { create(:work_package) }

      it "is not found" do
        expect { delete(planner_task_path(other), headers:) }.not_to change(WorkPackage, :count)
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "adding to My planner from a work package", with_flag: { planner: true } do
    let(:team_project) { create(:project) }
    let!(:work_package) { create(:work_package, project: team_project, subject: "Contact sponsoring partners") }
    let(:headers) { { "Accept" => "text/vnd.turbo-stream.html" } }

    context "when the user can see it" do
      before { create(:member, project: team_project, principal: user, roles: [role]) }

      it "opens the dialog for a to-do about it" do
        travel_to(user.time_zone.parse("#{user.today} 19:00")) do
          get(new_dialog_planner_tasks_path(work_package_id: work_package.display_id), headers:)
        end

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Add to My planner")
        expect(response.body).to include("planner-add-todo-work-package").and include("Contact sponsoring partners")
        expect(response.body).to match(/value="#{work_package.id}"[^>]*type="hidden" name="task\[work_package_id\]"/)
        expect(response.body).to match(/name="task\[day_part\]"[^>]*value="evening"|value="evening"[^>]*name="task\[day_part\]"/)
        expect(response.body).to include('name="task[subject]"').and include("augmented-text-area-description")
        expect(response.body).not_to include("planner-work-package-autocompleter")
        expect(response.body).to include('name="from_work_package"')
      end

      it "adds a to-do about it and confirms with a flash, without a view to refresh" do
        post(planner_tasks_path,
             params: { task: { work_package_id: work_package.id, subject: "Write Maya about the docs",
                               date: user.today.iso8601, day_part: "afternoon", description: "Docs for the API" },
                       from_work_package: true },
             headers:)

        task = WorkPackage.last
        expect(task).to have_attributes(subject: "Write Maya about the docs ##{work_package.display_id}",
                                        description: "Docs for the API")
        expect(Relation.where(from: task, to: work_package)).to exist
        expect(response.body).to include(%(action="closeDialog" target="#{Planner::AddTodoDialogComponent::DIALOG_ID}"))
        expect(response.body).to include("Added to Afternoon in My planner.")
        expect(response.body).not_to include("planner_sidemenu")
        expect(response.body).not_to include("planner-today")
      end
    end

    context "when the user cannot see it" do
      it "is not found" do
        get(new_dialog_planner_tasks_path(work_package_id: work_package.display_id), headers:)

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
