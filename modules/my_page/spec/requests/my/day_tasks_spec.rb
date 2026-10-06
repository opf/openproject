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

RSpec.describe "My Day tasks", :skip_csrf, type: :rails_request do
  let!(:task_type) { create(:type_task) }
  let!(:status) { create(:default_status) }
  let!(:priority) { create(:default_priority) }
  let!(:closed_status) { create(:closed_status) }
  let!(:role) do
    create(:project_role,
           permissions: ProjectRole::PERMISSIONS_FOR_PROJECT_CREATOR +
             %i[view_work_packages add_work_packages edit_work_packages])
  end
  let!(:workflow) { create(:status_transition, type: task_type, role:, old_status: status, new_status: closed_status) }
  let(:user) { create(:user) }
  let(:params) { { task: { subject: "Book train to the offsite", day_part: "evening" } } }

  current_user { user }

  subject { post my_day_tasks_path, params: }

  context "with the my_day flag", with_flag: { my_day: true } do
    it "adds the task to Today and goes back to My page" do
      expect { subject }.to change(WorkPackage, :count).by(1)
      expect(response).to redirect_to(my_page_path)
      expect(response).to have_http_status(:see_other)

      follow_redirect!
      expect(page).to have_test_selector("my-day-task-evening", text: "Book train to the offsite")
    end

    context "with a blank subject" do
      let(:params) { { task: { subject: "", day_part: "evening" } } }

      it "shows the error" do
        expect { subject }.not_to change(WorkPackage, :count)
        expect(flash[:error]).to be_present
      end
    end
  end

  describe "ticking a task off", with_flag: { my_day: true } do
    let(:task) { MyDay::CreateTaskService.new(user:).call(subject: "Book train", day_part: :evening).result }
    let(:headers) { { "Accept" => "text/vnd.turbo-stream.html" } }

    subject { patch my_day_task_path(task), params: { done: true }, headers: }

    it "closes it and re-renders Today" do
      subject

      expect(task.reload.status).to eq(closed_status)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('turbo-stream action="replace" target="my-day-today-component"')
    end

    context "with semantic identifiers", with_settings: { work_packages_identifier: "semantic" } do
      it "finds the task by its project-based id" do
        subject

        expect(my_day_task_path(task)).to end_with("/#{task.display_id}")
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

  describe "adding a work package", with_flag: { my_day: true } do
    let(:team_project) { create(:project) }
    let!(:work_package) { create(:work_package, project: team_project) }
    let(:headers) { { "Accept" => "text/vnd.turbo-stream.html" } }

    subject { post my_day_work_package_path(work_package.display_id), headers: }

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

  context "without the my_day flag" do
    it "is not found" do
      subject

      expect(response).to have_http_status(:not_found)
    end
  end
end
