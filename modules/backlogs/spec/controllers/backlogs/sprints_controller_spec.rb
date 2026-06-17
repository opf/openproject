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

RSpec.describe Backlogs::SprintsController do
  describe "new actions" do
    shared_let(:type_feature) { create(:type_feature) }
    shared_let(:type_task) { create(:type_task) }

    let(:all_permissions) { %i[view_sprints view_work_packages create_sprints start_complete_sprint show_board_views] }
    let(:permissions) { all_permissions }
    let(:user) do
      create(:user, member_with_permissions: { project => permissions })
    end
    let(:project) { create(:project) }

    current_user { user }

    describe "GET #index" do
      it "responds with success", :aggregate_failures do
        get :index, params: { project_id: project.id }

        expect(response).to be_successful
        expect(response).to have_http_status :ok
        expect(assigns(:project)).to eq(project)
        expect(assigns(:sprints)).not_to be_nil
        expect(assigns(:work_package_counts)).to be_a(Hash)
      end

      it "does not load a sprint from a stray sprint id" do
        sprint = create(:sprint, project:)

        get :index, params: { project_id: project.id, sprint_id: sprint.id }

        expect(response).to be_successful
        expect(assigns(:sprint)).to be_nil
      end
    end

    describe "GET #new_dialog" do
      it "responds with success", :aggregate_failures do
        get :new_dialog, params: { project_id: project.id }, format: :turbo_stream

        expect(response).to be_successful
        expect(response).to have_http_status :ok
        expect(response).to have_turbo_stream action: "dialog", target: "backlogs-sprint-dialog-component"
        expect(assigns(:project)).to eq(project)
      end

      context "without the 'create_sprints' permission" do
        let(:permissions) { all_permissions - [:create_sprints] }

        it "responds with forbidden", :aggregate_failures do
          get :new_dialog, params: { project_id: project.id }, format: :turbo_stream

          expect(response).not_to be_successful
          expect(response).to have_http_status :forbidden
        end
      end
    end

    describe "GET #edit_dialog" do
      let!(:sprint) { create(:sprint, project:) }

      it "responds with success", :aggregate_failures do
        get :edit_dialog, params: { project_id: project.id, sprint_id: sprint.id }, format: :turbo_stream

        expect(response).to be_successful
        expect(response).to have_http_status :ok
        expect(response).to have_turbo_stream action: "dialog", target: "backlogs-sprint-dialog-component"
        expect(assigns(:project)).to eq(project)
        expect(assigns(:sprint)).to eq(sprint)
      end

      context "without the 'create_sprints' permission" do
        let(:permissions) { all_permissions - [:create_sprints] }

        it "responds with forbidden", :aggregate_failures do
          get :edit_dialog, params: { project_id: project.id, sprint_id: sprint.id }, format: :turbo_stream

          expect(response).not_to be_successful
          expect(response).to have_http_status :forbidden
        end
      end
    end

    describe "POST #create" do
      let(:params) do
        {
          project_id: project.id,
          sprint: { name: "My Sprint", start_date: "2025-10-05", finish_date: "2025-10-15" }
        }
      end

      it "responds with success and redirects to backlogs", :aggregate_failures do
        post :create, format: :turbo_stream, params: params

        expect(response).to be_successful
        expect(response).to have_http_status :ok
        expect(response.body).to include("turbo-stream")
        expect(response.body).to have_turbo_stream(
          action: "redirect_to",
          url: project_backlogs_backlog_path(project)
        )
        expect(flash[:notice]).to eq(I18n.t(:notice_successful_create))
      end

      context "when all=1 is passed" do
        it "redirects to backlogs preserving the all param" do
          post :create, format: :turbo_stream, params: params.merge(all: 1)

          expect(response.body).to include(project_backlogs_backlog_path(project, all: 1))
        end
      end

      context "with a sprint goal" do
        let(:params) do
          {
            project_id: project.id,
            sprint: {
              name: "My Sprint",
              start_date: "2025-10-05",
              finish_date: "2025-10-15",
              goal: { text: "Ship MVP" }
            }
          }
        end

        it "creates the goal for the route project" do
          expect { post :create, format: :turbo_stream, params: params }
            .to change(SprintGoal, :count).by(1)

          sprint = Sprint.find_by!(name: "My Sprint")
          expect(sprint.goal_text_for(project)).to eq("Ship MVP")
        end

        context "with a submitted goal project id" do
          let(:other_project) { create(:project) }

          let(:params) do
            {
              project_id: project.id,
              sprint: {
                name: "My Sprint",
                start_date: "2025-10-05",
                finish_date: "2025-10-15",
                goal: { text: "Ship MVP", project_id: other_project.id }
              }
            }
          end

          it "ignores the submitted project id" do
            post :create, format: :turbo_stream, params: params

            sprint = Sprint.find_by!(name: "My Sprint")
            expect(sprint.goal_text_for(project)).to eq("Ship MVP")
            expect(sprint.goal_text_for(other_project)).to be_nil
          end
        end

        context "with a submitted sprint id" do
          let!(:other_sprint) { create(:sprint, project:) }
          let!(:other_goal) { create(:sprint_goal, sprint: other_sprint, project:, text: "Other goal") }
          let(:params) do
            {
              project_id: project.id,
              sprint: {
                id: other_sprint.id,
                name: "My Sprint",
                start_date: "2025-10-05",
                finish_date: "2025-10-15",
                goal: { text: "Ship MVP" }
              }
            }
          end

          it "ignores the submitted sprint id" do
            post :create, format: :turbo_stream, params: params

            sprint = Sprint.find_by!(name: "My Sprint")
            expect(sprint).to have_attributes(project_id: project.id)
            expect(sprint.goal_text_for(project)).to eq("Ship MVP")
            expect(other_goal.reload.text).to eq("Other goal")
          end
        end
      end

      context "without the 'create_sprints' permission" do
        let(:permissions) { all_permissions - [:create_sprints] }

        it "responds with forbidden", :aggregate_failures do
          post :create, format: :turbo_stream, params: params

          expect(response).not_to be_successful
          expect(response).to have_http_status :forbidden
        end
      end
    end

    describe "PUT #update" do
      let!(:sprint) { create(:sprint, name: "Original sprint name", project:) }

      let(:params) do
        {
          project_id: project.id,
          sprint_id: sprint.id,
          sprint: { name: "Changed sprint name" }
        }
      end

      it "responds with success via the namespaced update action", :aggregate_failures do
        put :update, format: :turbo_stream, params: params

        expect(response).to be_successful
        expect(response).to have_http_status :ok
        expect(response.body).to have_turbo_stream action: "flash"
        expect(response.body).to have_turbo_stream action: "update", target: "backlogs-sprint-component-#{sprint.id}"
        assert_select %(turbo-stream[action="update"][target="backlogs-sprint-component-#{sprint.id}"][method="morph"])
        expect(response.body).to include("Successful update.")
        expect(controller.controller_path).to eq("backlogs/sprints")
        expect(controller.action_name).to eq("update")
      end

      context "with a sprint goal" do
        let(:params) do
          {
            project_id: project.id,
            sprint_id: sprint.id,
            sprint: { goal: { text: "Ship MVP" } }
          }
        end

        it "updates the goal for the route project" do
          expect { put :update, format: :turbo_stream, params: params }
            .to change(SprintGoal, :count).by(1)

          expect(sprint.reload.goal_text_for(project)).to eq("Ship MVP")
        end

        context "with a submitted goal project id" do
          let(:other_project) { create(:project) }
          let(:params) do
            {
              project_id: project.id,
              sprint_id: sprint.id,
              sprint: { goal: { text: "Ship MVP", project_id: other_project.id } }
            }
          end

          it "ignores the submitted project id" do
            put :update, format: :turbo_stream, params: params

            expect(sprint.reload.goal_text_for(project)).to eq("Ship MVP")
            expect(sprint.goal_text_for(other_project)).to be_nil
          end
        end

        context "with a submitted goal id from another project" do
          let(:other_project) { create(:project) }
          let!(:other_goal) { create(:sprint_goal, sprint:, project: other_project, text: "Other project goal") }
          let(:params) do
            {
              project_id: project.id,
              sprint_id: sprint.id,
              sprint: { goal: { id: other_goal.id, text: "Ship MVP" } }
            }
          end

          it "ignores the submitted goal id" do
            expect { put :update, format: :turbo_stream, params: params }
              .to change(SprintGoal, :count).by(1)

            expect(sprint.reload.goal_text_for(project)).to eq("Ship MVP")
            expect(other_goal.reload).to have_attributes(project_id: other_project.id, text: "Other project goal")
          end
        end

        context "when clearing with a submitted goal id from another project" do
          let(:other_project) { create(:project) }
          let!(:other_goal) { create(:sprint_goal, sprint:, project: other_project, text: "Other project goal") }
          let(:params) do
            {
              project_id: project.id,
              sprint_id: sprint.id,
              sprint: { goal: { id: other_goal.id, text: "" } }
            }
          end

          it "does not destroy the submitted goal id" do
            expect { put :update, format: :turbo_stream, params: params }
              .not_to change(SprintGoal, :count)

            expect(sprint.reload.goal_text_for(project)).to be_nil
            expect(other_goal.reload).to have_attributes(project_id: other_project.id, text: "Other project goal")
          end
        end

        context "when clearing an existing goal" do
          let!(:goal) { create(:sprint_goal, sprint:, project:, text: "Old goal") }
          let(:params) do
            {
              project_id: project.id,
              sprint_id: sprint.id,
              sprint: { goal: { text: "" } }
            }
          end

          it "destroys the existing goal" do
            expect { put :update, format: :turbo_stream, params: params }
              .to change(SprintGoal, :count).by(-1)

            expect(sprint.reload.goal_text_for(project)).to be_nil
          end
        end
      end

      context "without the 'create_sprints' permission" do
        let(:permissions) { all_permissions - [:create_sprints] }

        it "responds with forbidden", :aggregate_failures do
          put :update, format: :turbo_stream, params: params

          expect(response).not_to be_successful
          expect(response).to have_http_status :forbidden
        end
      end
    end

    describe "POST #start" do
      let!(:sprint) { create(:sprint, project:) }
      let(:service_result) { ServiceResult.success(result: sprint.tap { it.status = "active" }) }
      let(:service) { instance_double(Backlogs::Sprints::StartService, call: service_result) }
      let(:request_params) { { project_id: project.id, sprint_id: sprint.id } }

      before do
        allow(Backlogs::Sprints::StartService)
          .to receive(:new)
          .with(user:, model: sprint)
          .and_return(service)
      end

      context "when the sprint is rendered in a receiving project" do
        let(:source_project) { create(:project, sprint_sharing: "share_all_projects") }
        let(:project) { create(:project, sprint_sharing: "receive_shared") }
        let!(:sprint) { create(:sprint, project: source_project) }
        let(:source_permissions) { %i[view_sprints start_complete_sprint] }
        let!(:board) { create(:board_grid_with_query, project:, linked: sprint) }

        before do
          create(:member,
                 project: source_project,
                 principal: user,
                 roles: [create(:project_role, permissions: source_permissions)])
        end

        it "starts the sprint and redirects to the board", :aggregate_failures do
          post :start, format: :turbo_stream, params: request_params

          expect(response).to be_successful
          expect(response).to have_turbo_stream(action: "redirect_to")
          expect(service).to have_received(:call)
        end

        context "without source-project start permission" do
          let(:source_permissions) { %i[view_sprints] }

          it "responds with forbidden and does not call the service", :aggregate_failures do
            post :start, params: request_params

            expect(response).not_to be_successful
            expect(response).to have_http_status(:forbidden)
            expect(service).not_to have_received(:call)
          end
        end

        context "without rendered-project board access" do
          let(:permissions) { all_permissions - [:show_board_views] }

          it "responds with forbidden and does not call the service", :aggregate_failures do
            post :start, params: request_params

            expect(response).not_to be_successful
            expect(response).to have_http_status(:forbidden)
            expect(service).not_to have_received(:call)
          end
        end
      end

      context "when a board already exists" do
        let!(:existing_board) do
          create(:board_grid_with_query,
                 project:,
                 linked: sprint)
        end

        it "starts the sprint and redirects to the board", :aggregate_failures do
          post :start, format: :turbo_stream, params: request_params

          expect(response).to be_successful
          expect(response).to have_turbo_stream(action: "redirect_to")
          expect(service).to have_received(:call)
        end
      end

      context "when board creation succeeds" do
        let(:board) { create(:board_grid_with_query, project:, linked: sprint) }
        let(:service_result) do
          started_sprint = sprint.tap { it.status = "active" }
          allow(started_sprint).to receive(:task_board_for).with(project).and_return(board)

          ServiceResult.success(
            result: started_sprint
          )
        end

        it "creates the board, starts the sprint, and redirects to the board", :aggregate_failures do
          post :start, format: :turbo_stream, params: request_params

          expect(response).to be_successful
          expect(response).to have_turbo_stream(action: "redirect_to")
          expect(flash[:notice]).to eq(I18n.t(:notice_successful_start))
          expect(service).to have_received(:call)
        end
      end

      context "when board creation fails" do
        let(:service_result) { ServiceResult.failure(message: "something went wrong") }

        it "redirects back to the backlog", :aggregate_failures do
          post :start, params: request_params

          expect(response).to redirect_to(project_backlogs_backlog_path(project))
          expect(flash[:alert]).to eq(
            I18n.t(:notice_unsuccessful_start_with_reason, reason: "something went wrong")
          )
        end
      end

      context "when sprint start fails without an explicit message" do
        let(:service_result) { ServiceResult.failure }

        it "redirects back with the default start failure message", :aggregate_failures do
          post :start, params: request_params

          expect(response).to redirect_to(project_backlogs_backlog_path(project))
          expect(flash[:alert]).to eq(I18n.t(:notice_unsuccessful_start))
          expect(service).to have_received(:call)
        end
      end

      context "when another sprint is already active" do
        let!(:active_sprint) { create(:sprint, project:, status: "active") }
        let(:service_result) do
          ServiceResult.failure(
            result: sprint,
            message: sprint.errors.full_messages.to_sentence
          )
        end

        it "redirects back to the backlog", :aggregate_failures do
          post :start, params: request_params

          expect(response).to redirect_to(project_backlogs_backlog_path(project))
          expect(flash[:alert]).to eq(I18n.t(:notice_unsuccessful_start))
          expect(service).to have_received(:call)
        end
      end

      context "without the 'start_complete_sprint' permission" do
        let(:permissions) { all_permissions - [:start_complete_sprint] }

        it "responds with forbidden", :aggregate_failures do
          post :start, params: request_params

          expect(response).not_to be_successful
          expect(response).to have_http_status(:forbidden)
        end
      end

      context "when the sprint is already active" do
        let!(:sprint) { create(:sprint, project:, status: "active") }
        let(:service_result) { ServiceResult.failure }

        it "redirects back with the default start failure message", :aggregate_failures do
          post :start, params: request_params

          expect(response).to redirect_to(project_backlogs_backlog_path(project))
          expect(flash[:alert]).to eq(I18n.t(:notice_unsuccessful_start))
          expect(service).to have_received(:call)
        end
      end
    end

    describe "POST #finish" do
      let!(:sprint) { create(:sprint, project:, status: "active") }
      let(:request_params) { { project_id: project.id, sprint_id: sprint.id } }
      let(:service_result) do
        ServiceResult.success(
          result: sprint.tap { |finished_sprint| finished_sprint.status = "completed" }
        )
      end
      let(:service) { instance_double(Backlogs::Sprints::FinishService, call: service_result) }

      before do
        allow(Backlogs::Sprints::FinishService)
          .to receive(:new)
          .with(user:, model: sprint)
          .and_return(service)
      end

      context "when the sprint is rendered in a receiving project" do
        let(:source_project) { create(:project, sprint_sharing: "share_all_projects") }
        let(:project) { create(:project, sprint_sharing: "receive_shared") }
        let!(:sprint) { create(:sprint, project: source_project, status: "active") }
        let(:source_permissions) { %i[view_sprints start_complete_sprint] }

        before do
          create(:member,
                 project: source_project,
                 principal: user,
                 roles: [create(:project_role, permissions: source_permissions)])
        end

        it "finishes the sprint and redirects to the backlog", :aggregate_failures do
          post :finish, params: request_params

          expect(response).to be_successful
          expect(response.body).to have_turbo_stream(
            action: "redirect_to",
            url: project_backlogs_backlog_path(project)
          )
          expect(flash[:notice]).to eq(I18n.t(:notice_successful_finish))
          expect(service).to have_received(:call)
        end

        context "without source-project start permission" do
          let(:source_permissions) { %i[view_sprints] }

          it "responds with forbidden and does not call the service", :aggregate_failures do
            post :finish, params: request_params

            expect(response).not_to be_successful
            expect(response).to have_http_status(:forbidden)
            expect(service).not_to have_received(:call)
          end
        end
      end

      it "finishes the sprint and redirects to the backlog via turbo stream", :aggregate_failures do
        post :finish, format: :turbo_stream, params: request_params

        expect(response).to be_successful
        expect(response.body).to have_turbo_stream(
          action: "redirect_to",
          url: project_backlogs_backlog_path(project)
        )
        expect(flash[:notice]).to eq(I18n.t(:notice_successful_finish))
        expect(service).to have_received(:call)
      end

      context "when finishing fails" do
        let(:service_result) { ServiceResult.failure(message: "something went wrong") }

        it "redirects back to the backlog", :aggregate_failures do
          post :finish, params: request_params

          expect(response).to redirect_to(project_backlogs_backlog_path(project))
          expect(flash[:alert]).to eq(
            I18n.t(:notice_unsuccessful_finish_with_reason, reason: "something went wrong")
          )
          expect(service).to have_received(:call)
        end
      end

      context "when finishing fails without an explicit message" do
        let(:service_result) { ServiceResult.failure }

        it "redirects back with the default finish failure message", :aggregate_failures do
          post :finish, params: request_params

          expect(response).to redirect_to(project_backlogs_backlog_path(project))
          expect(flash[:alert]).to eq(I18n.t(:notice_unsuccessful_finish))
          expect(service).to have_received(:call)
        end
      end

      context "without the 'start_complete_sprint' permission" do
        let(:permissions) { all_permissions - [:start_complete_sprint] }

        it "responds with forbidden", :aggregate_failures do
          post :finish, params: request_params

          expect(response).not_to be_successful
          expect(response).to have_http_status(:forbidden)
        end
      end

      context "when the sprint is already completed" do
        let!(:sprint) { create(:sprint, project:, status: "completed") }
        let(:service_result) { ServiceResult.failure }

        it "redirects back with the default finish failure message", :aggregate_failures do
          post :finish, params: request_params

          expect(response).to redirect_to(project_backlogs_backlog_path(project))
          expect(flash[:alert]).to eq(I18n.t(:notice_unsuccessful_finish))
          expect(service).to have_received(:call)
        end
      end

      context "when moving to the top of the backlog" do
        let(:request_params) { { project_id: project.id, sprint_id: sprint.id, unfinished_action: "move_to_top_of_backlog" } }

        it "passes unfinished_action to the service and redirects via turbo stream", :aggregate_failures do
          post :finish, format: :turbo_stream, params: request_params

          expect(response).to be_successful
          expect(response.body).to have_turbo_stream(action: "redirect_to")

          expect(service).to have_received(:call)
            .with(hash_including(unfinished_action: "move_to_top_of_backlog"))
        end
      end

      context "when moving to the bottom of the backlog" do
        let(:request_params) { { project_id: project.id, sprint_id: sprint.id, unfinished_action: "move_to_bottom_of_backlog" } }

        it "passes unfinished_action to the service and redirects via turbo stream", :aggregate_failures do
          post :finish, format: :turbo_stream, params: request_params

          expect(response).to be_successful
          expect(response.body).to have_turbo_stream(action: "redirect_to")

          expect(service).to have_received(:call)
            .with(hash_including(unfinished_action: "move_to_bottom_of_backlog"))
        end
      end
    end

    describe "GET #refresh_form" do
      let(:params) do
        {
          project_id: project.id,
          sprint: { name: "My Sprint", start_date: "2025-10-05", finish_date: "2025-10-15" }
        }
      end

      it "responds with success", :aggregate_failures do
        get :refresh_form, format: :turbo_stream, params: params

        expect(response).to be_successful
        expect(response).to have_http_status :ok
        expect(response).to have_turbo_stream action: "update", target: "backlogs-sprint-form-component"
        expect(assigns(:sprint)).to be_nil
      end

      context "without the 'create_sprints' permission" do
        let(:permissions) { all_permissions - [:create_sprints] }

        it "responds with forbidden", :aggregate_failures do
          get :refresh_form, format: :turbo_stream, params: params

          expect(response).not_to be_successful
          expect(response).to have_http_status :forbidden
        end
      end

      context "when refreshing the form in edit mode by passing a sprint id" do
        let!(:sprint) { create(:sprint, project:) }
        let(:params) do
          {
            project_id: project.id,
            sprint: { id: sprint.id, name: "My Sprint", start_date: "2025-10-05", finish_date: "2025-10-15" }
          }
        end

        it "responds with success", :aggregate_failures do
          get :refresh_form, format: :turbo_stream, params: params

          expect(response).to be_successful
          expect(response).to have_http_status :ok
          expect(response).to have_turbo_stream action: "update", target: "backlogs-sprint-form-component"
        end
      end
    end

    describe "shared sprint authorization" do
      let(:source_project) { create(:project, sprint_sharing: "share_all_projects") }
      let(:project) { create(:project, sprint_sharing: "receive_shared") }
      let!(:sprint) { create(:sprint, project: source_project) }
      let(:role_with_perm) { create(:project_role, permissions: %i[view_sprints create_sprints]) }
      let(:role_without_perm) { create(:project_role, permissions: %i[view_sprints]) }
      let(:role_without_sprint_access) { create(:project_role, permissions: []) }

      describe "GET #edit_dialog" do
        context "when user has create_sprints only in the viewing project" do
          let(:user) do
            create(:user,
                   member_with_roles: { project => role_with_perm, source_project => role_without_perm })
          end

          it "responds with success", :aggregate_failures do
            get :edit_dialog, params: { project_id: project.id, sprint_id: sprint.id }, format: :turbo_stream

            expect(response).to be_successful
          end
        end

        context "when user has create_sprints only in the defining project" do
          let(:user) do
            create(:user,
                   member_with_roles: { project => role_without_perm, source_project => role_with_perm })
          end

          it "responds with success", :aggregate_failures do
            get :edit_dialog, params: { project_id: project.id, sprint_id: sprint.id }, format: :turbo_stream

            expect(response).to be_successful
          end
        end

        context "when user has create_sprints in the defining project but no view_sprints in the viewing project" do
          let(:user) do
            create(:user,
                   member_with_roles: { project => role_without_sprint_access, source_project => role_with_perm })
          end

          it "responds with forbidden" do
            get :edit_dialog, params: { project_id: project.id, sprint_id: sprint.id }, format: :turbo_stream

            expect(response).to have_http_status(:forbidden)
          end
        end

        context "when user has no view_sprints in the viewing project and no create_sprints in either project" do
          let(:user) do
            create(:user,
                   member_with_roles: { project => role_without_sprint_access, source_project => role_without_perm })
          end

          it "responds with forbidden" do
            get :edit_dialog, params: { project_id: project.id, sprint_id: sprint.id }, format: :turbo_stream

            expect(response).to have_http_status(:forbidden)
          end
        end

        context "when user has create_sprints in neither project" do
          let(:user) do
            create(:user,
                   member_with_roles: { project => role_without_perm, source_project => role_without_perm })
          end

          it "responds with forbidden" do
            get :edit_dialog, params: { project_id: project.id, sprint_id: sprint.id }, format: :turbo_stream

            expect(response).to have_http_status(:forbidden)
          end
        end
      end

      describe "PUT #update" do
        context "when user has create_sprints only in the viewing project" do
          let(:user) do
            create(:user,
                   member_with_roles: { project => role_with_perm, source_project => role_without_perm })
          end

          it "allows the request", :aggregate_failures do
            put :update,
                format: :turbo_stream,
                params: { project_id: project.id, sprint_id: sprint.id, sprint: { goal: { text: "Ship MVP" } } }

            expect(response).to be_successful
          end

          it "does not update sprint attributes" do
            put :update,
                format: :turbo_stream,
                params: { project_id: project.id, sprint_id: sprint.id, sprint: { name: "Renamed" } }

            expect(response).to have_http_status(:bad_request)
            expect(sprint.reload.name).not_to eq("Renamed")
          end
        end

        context "when user has create_sprints only in the defining project" do
          let(:user) do
            create(:user,
                   member_with_roles: { project => role_without_perm, source_project => role_with_perm })
          end

          it "allows the request", :aggregate_failures do
            put :update,
                format: :turbo_stream,
                params: { project_id: project.id, sprint_id: sprint.id, sprint: { name: "Renamed" } }

            expect(response).to be_successful
          end
        end

        context "when user has create_sprints in the defining project but no view_sprints in the viewing project" do
          let(:user) do
            create(:user,
                   member_with_roles: { project => role_without_sprint_access, source_project => role_with_perm })
          end

          it "responds with forbidden" do
            put :update,
                format: :turbo_stream,
                params: { project_id: project.id, sprint_id: sprint.id, sprint: { name: "Renamed" } }

            expect(response).to have_http_status(:forbidden)
          end
        end

        context "when user has create_sprints in neither project" do
          let(:user) do
            create(:user,
                   member_with_roles: { project => role_without_perm, source_project => role_without_perm })
          end

          it "responds with forbidden" do
            put :update,
                format: :turbo_stream,
                params: { project_id: project.id, sprint_id: sprint.id, sprint: { name: "Renamed" } }

            expect(response).to have_http_status(:forbidden)
          end
        end
      end

      describe "GET #refresh_form for shared sprint" do
        let(:user) do
          create(:user,
                 member_with_roles: { project => role_with_perm, source_project => role_without_perm })
        end

        it "preserves the sprint's defining project context", :aggregate_failures do
          get :refresh_form,
              format: :turbo_stream,
              params: {
                project_id: project.id,
                sprint: { id: sprint.id, name: sprint.name }
              }

          expect(response).to be_successful
          expect(response.body).to include(
            I18n.t("backlogs.sprint_form_component.shared_sprint_warning_banner")
          )
        end
      end
    end
  end
end
