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

RSpec.describe ProjectsController do
  shared_let(:admin) { create(:admin) }

  let(:user) { admin }

  before do
    login_as user
  end

  describe "#new" do
    shared_examples_for "successful requests" do
      context "without a parent" do
        let(:parent) { nil }

        context "without a template" do
          let(:template) { nil }

          it_behaves_like "successful request"
        end

        context "with a template" do
          let(:template) { create(:template_project) }

          it_behaves_like "successful request"
        end
      end

      context "with a parent" do
        let(:parent) { create(:project) }

        context "without a template" do
          let(:template) { nil }

          it_behaves_like "successful request"
        end

        context "with a template" do
          let(:template) { create(:template_project) }

          it_behaves_like "successful request"
        end
      end
    end

    shared_examples_for "successful request" do
      it "renders 'new'", :aggregate_failures do
        expect(response).to be_successful
        expect(assigns(:new_project)).to be_a_new(Project)
        expect(assigns(:parent)).to eq parent
        expect(assigns(:template)).to eq template
        expect(response).to render_template "new"
      end
    end

    let(:workspace_type) { "project" }

    before do
      get :new, params: { parent_id: parent&.id, template_id: template&.id, workspace_type: }
    end

    context "as an admin" do
      it_behaves_like "successful requests"
    end

    context "as a non-admin with global add_project permission" do
      let(:user) { create(:user, global_permissions: [:add_project]) }
      let(:template) { nil }

      context "without a parent" do
        let(:parent) { nil }

        it_behaves_like "successful request"
      end

      context "with a parent with public permissions" do
        let(:user) { create(:user, global_permissions: [:add_project], member_with_permissions: { parent => [] }) }
        let(:parent) { create(:project) }

        it_behaves_like "successful request"
      end
    end

    context "as a non-admin without global add_project permission" do
      let(:user) { create(:user, global_permissions: []) }
      let(:template) { nil }

      context "without a parent" do
        let(:parent) { nil }

        it "returns 403 Not Authorized" do
          expect(response).not_to be_successful
          expect(response).to have_http_status :forbidden
        end
      end

      context "with a parent with add_subprojects permissions" do
        let(:user) { create(:user, member_with_permissions: { parent => [:add_subprojects] }) }
        let(:parent) { create(:project) }
        let(:template) { nil }

        it_behaves_like "successful request"
      end
    end

    context "when not being logged in but login is required", with_settings: { login_required: true } do
      let(:user) { User.anonymous }
      let(:workspace_type) { "portfolio" }
      let(:parent) { build_stubbed(:project) }
      let(:template) { build_stubbed(:project) }

      it "redirects to the sign in page with the parameters provided in the back url" do
        expect(response).to be_redirect
        expect(response).to redirect_to signin_path(back_url: new_project_url(parent_id: parent.id,
                                                                              template_id: template.id))
      end
    end
  end

  describe "#create" do
    describe "permission checks" do
      let(:project) { build_stubbed(:project) }
      let(:service_result) { ServiceResult.success(result: project) }
      let(:parent) { nil }

      before do
        creation_service = instance_double(Projects::CreateService, call: service_result)

        allow(Projects::CreateService)
          .to receive(:new)
                .with(user:)
                .and_return(creation_service)

        post :create, params: { project: { name: "New Project" }, parent_id: parent&.id }
      end

      shared_examples_for "successful create request" do
        it "redirects to project show", :aggregate_failures do
          expect(response).to redirect_to project_path(project)
          expect(flash[:notice]).to eq I18n.t(:notice_successful_create)
        end
      end

      shared_examples_for "forbidden create request" do
        it "returns 403 Not Authorized" do
          expect(response).not_to be_successful
          expect(response).to have_http_status :forbidden
        end
      end

      context "as an admin" do
        it_behaves_like "successful create request"

        context "with a parent" do
          let(:parent) { create(:project) }

          it_behaves_like "successful create request"
        end
      end

      context "as a non-admin with global add_project permission" do
        let(:user) { create(:user, global_permissions: [:add_project]) }

        it_behaves_like "successful create request"

        context "with a parent with public permissions" do
          let(:user) { create(:user, global_permissions: [:add_project], member_with_permissions: { parent => [] }) }
          let(:parent) { create(:project) }

          it_behaves_like "successful create request"
        end
      end

      context "as a non-admin without global add_project permission" do
        let(:user) { create(:user, global_permissions: []) }

        it_behaves_like "forbidden create request"

        context "with a parent with add_subprojects permissions" do
          let(:user) { create(:user, member_with_permissions: { parent => [:add_subprojects] }) }
          let(:parent) { create(:project) }

          it_behaves_like "successful create request"
        end
      end
    end

    context "without a template" do
      let(:workspace_type_param) { { workspace_type: "project" } }

      context "when submitted from step 1" do
        let(:project) { Project.new }
        let(:service_result) { ServiceResult.failure(result: project, message: "Name can't be blank.") }

        it "clears custom field errors", :aggregate_failures do
          post :create, params: {
            project: workspace_type_param.merge({ name: "" }),
            step: 1
          }

          new_project = assigns(:new_project)
          expect(new_project.errors.select { |error| error.attribute.to_s.start_with?("custom_field") }).to be_empty
        end
      end

      context "when submitted from step 2" do
        let(:project) { Project.new }

        before do
          post :create, params: {
            project: workspace_type_param.merge(project_params),
            step: 2
          }
        end

        context "when there is a required custom field" do
          shared_let(:custom_field) { create(:string_project_custom_field, is_required: true, is_for_all: true) }

          context "when the name is missing" do
            let(:project_params) { { name: "" } }

            it "renders step 2 with errors", :aggregate_failures do
              expect(controller.params[:step].to_i).to eq 2
              expect(response).to render_template "new"
              expect(response).to have_http_status :unprocessable_entity
            end

            it "shows an error on the name", :aggregate_failures do
              expect(assigns(:new_project).errors[:name]).to be_present
              expect(flash[:error])
                .to eq I18n.t(:notice_unsuccessful_create_with_reason, reason: "Name can't be blank.")
            end

            it "does not show custom field errors", :aggregate_failures do
              expect(assigns(:new_project).errors[:"custom_field_#{custom_field.id}"]).to be_empty
              assigns(:new_project).custom_values.each do |cv|
                expect(cv.errors).to be_empty
              end
            end
          end

          context "when the parent is invalid" do
            shared_let(:invalid_parent) { create(:project, workspace_type: :program) }
            let(:project_params) { { name: "Valid Project", parent_id: invalid_parent.id, workspace_type: :portfolio } }

            it "renders step 2 with errors", :aggregate_failures do
              expect(controller.params[:step].to_i).to eq 2
              expect(response).to render_template "new"
              expect(response).to have_http_status :unprocessable_entity
            end

            it "shows an error on the parent", :aggregate_failures do
              expect(assigns(:new_project).errors[:parent]).to be_present
              expect(flash[:error]).to be_present
            end

            it "does not show custom field errors", :aggregate_failures do
              expect(assigns(:new_project).errors[:"custom_field_#{custom_field.id}"]).to be_empty
              assigns(:new_project).custom_values.each do |cv|
                expect(cv.errors).to be_empty
              end
            end
          end

          context "when it has no validation error on name" do
            let(:project_params) { { name: "Valid Project" } }

            it "advances to step 3 without errors", :aggregate_failures do
              expect(controller.params[:step].to_i).to eq 3
              expect(response).to render_template "new"
              expect(response).to have_http_status :unprocessable_entity
            end

            it "does not show custom field errors", :aggregate_failures do
              expect(assigns(:new_project).errors[:"custom_field_#{custom_field.id}"]).to be_empty
              assigns(:new_project).custom_values.each do |cv|
                expect(cv.errors).to be_empty
              end
              expect(flash[:error]).to be_nil
            end
          end

          # It is not possible to submit these params with the wizard in place,
          # because the custom fields cannot be submitted in the second step.
          # However, this test just ensures that no tampering with the params
          # will result in an unexpected behavior.
          context "when there is no validation error on the custom field" do
            let(:project_params) do
              {
                name: "Valid Project",
                custom_field_values: { custom_field.id => "Valid Value" }
              }
            end

            it "creates the project successfully", :aggregate_failures do
              expect(response).to redirect_to project_path(assigns(:new_project))
              expect(flash[:notice]).to eq I18n.t(:notice_successful_create)
            end
          end
        end

        context "when there is no required custom field" do
          context "when the name is missing" do
            let(:project_params) { { name: "" } }

            it "renders step 2 with errors", :aggregate_failures do
              expect(controller.params[:step].to_i).to eq 2
              expect(response).to render_template "new"
              expect(response).to have_http_status :unprocessable_entity
            end

            it "shows an error on the name", :aggregate_failures do
              expect(assigns(:new_project).errors[:name]).to be_present
              expect(flash[:error])
                .to eq I18n.t(:notice_unsuccessful_create_with_reason, reason: "Name can't be blank.")
            end
          end

          context "when the name is present" do
            let(:project_params) { { name: "Valid Project" } }

            it "creates the project successfully", :aggregate_failures do
              expect(response).to redirect_to project_path(assigns(:new_project))
              expect(flash[:notice]).to eq I18n.t(:notice_successful_create)
            end
          end
        end
      end

      context "when submitted from step 3" do
        shared_let(:custom_field) { create(:string_project_custom_field, is_required: true, is_for_all: true) }

        it "does not clear custom field errors", :aggregate_failures do
          post :create,
               params: { project: workspace_type_param.merge({ name: "Valid Project" }), step: 3 }

          expect(assigns(:new_project).errors[:"custom_field_#{custom_field.id}"])
            .to be_present
          expect(flash[:error])
            .to eq I18n.t(:notice_unsuccessful_create_with_reason,
                          reason: "#{custom_field.name} can't be blank.")
        end
      end
    end

    context "with a template" do
      let(:template) { create(:template_project, workspace_type:) }

      before do
        copy_service = instance_double(Projects::EnqueueCopyService)

        allow(Projects::EnqueueCopyService)
         .to receive(:new)
               .with(user: admin, model: template)
               .and_return(copy_service)
        dependencies = %w[
          boards storages storage_project_folders forums phases members overview
          versions wiki wiki_page_attachments work_packages work_package_attachments
          categories file_links queries work_package_shares
        ]
        allow(copy_service)
          .to receive(:call)
              .with(
                target_project_params: { "name" => name, "template" => template },
                only: dependencies,
                skip_custom_field_validation: true,
                send_notifications: false
              ).and_return(service_result)

        post :create, params: {
          template_id: template.id,
          workspace_type:,
          project: { name: },
          copy_options: { send_notifications: false }
        }
      end

      context "when service call succeeds" do
        let(:workspace_type) { "project" }
        let(:name) { "Copied project" }
        let(:job) { CopyProjectJob.new }
        let(:service_result) { ServiceResult.success(result: job) }

        it "redirects to job status", :aggregate_failures do
          expect(response).to redirect_to job_status_path(job.job_id)
        end
      end

      context "when service call fails" do
        let(:name) { "" }
        let(:project) { Project.new }
        let(:service_result) { ServiceResult.failure(result: project, message: "") }

        %w[portfolio program project].each do |workspace_type|
          context "for workspace type #{workspace_type}" do
            let(:workspace_type) { workspace_type }

            it "renders new template with errors", :aggregate_failures do
              expect(response).not_to be_successful
              expect(response).to have_http_status :unprocessable_entity
              expect(assigns(:new_project)).to be_a_new(Project)
              expect(assigns(:new_project)).not_to be_valid
              expect(assigns(:template)).not_to be_nil
              expect(assigns(:copy_options)).not_to be_nil
              expect(flash[:error]).to start_with I18n.t(:notice_unsuccessful_create_with_reason, reason: "")
              expect(response).to render_template "new"
            end
          end
        end
      end
    end
  end

  describe "#index" do
    shared_let(:project_a) { create(:project, name: "Project A", public: false, active: true) }
    shared_let(:project_b) { create(:project, name: "Project B", public: false, active: true) }
    shared_let(:project_c) { create(:project, name: "Project C", public: true, active: true) }
    shared_let(:project_d) { create(:project, name: "Project D", public: true, active: false) }

    before do
      ProjectRole.anonymous
      ProjectRole.non_member

      login_as(user)
      get "index"
    end

    shared_examples_for "successful index" do
      it "is success" do
        expect(response).to be_successful
      end

      it "renders the index template" do
        expect(response).to render_template "index"
      end
    end

    it_behaves_like "successful index"
  end

  describe "#destroy" do
    render_views

    let(:project) { build_stubbed(:project) }
    let(:request) { delete :destroy, params: { id: project.id } }

    let(:service_result) { ServiceResult.new(success:) }

    before do
      allow(Project).to receive(:find).with(project.id.to_s).and_return(project)

      deletion_service = instance_double(Projects::ScheduleDeletionService,
                                         call: service_result)

      allow(Projects::ScheduleDeletionService)
        .to receive(:new)
              .with(user: admin, model: project)
              .and_return(deletion_service)
    end

    context "when service call succeeds" do
      let(:success) { true }

      it "prints success" do
        request
        expect(response).to be_redirect
        expect(flash[:notice]).to be_present
      end
    end

    context "when service call fails" do
      let(:success) { false }

      it "prints fail" do
        request
        expect(response).to be_redirect
        expect(flash[:error]).to be_present
      end
    end
  end

  describe "with an existing project" do
    let(:project) { create(:project, identifier: "blog") }

    it "gets destroy info" do
      get :destroy_info, params: { id: project.id }, format: :turbo_stream
      expect(response).to be_successful
      expect(response).to have_turbo_stream action: "dialog", target: "projects-delete-dialog-component"

      expect { project.reload }.not_to raise_error
    end
  end

  describe "#copy_form" do
    let(:project) { create(:project, identifier: "blog") }

    shared_examples_for "successful request" do
      it "renders 'copy_form'", :aggregate_failures do
        expect(response).to be_successful
        expect(assigns(:target_project)).to be_a_new(Project)
        expect(assigns(:project)).to eq project
        expect(response).to render_template "copy_form"
      end
    end

    before do
      get "copy_form", params: { id: project.identifier }
    end

    context "as an admin" do
      it_behaves_like "successful request"
    end

    context "as a non-admin with copy_projects permissions" do
      let(:user) { create(:user, member_with_permissions: { project => [:copy_projects] }) }

      it_behaves_like "successful request"
    end

    context "as a non-admin without copy_projects permissions" do
      let(:user) { build_stubbed(:user) }

      it "returns 404 Not Found" do
        expect(response).not_to be_successful
        expect(response).to have_http_status :not_found
      end
    end
  end

  describe "#copy" do
    let(:project) { create(:project, identifier: "blog") }

    before do
      copy_service = instance_double(Projects::EnqueueCopyService)

      allow(Projects::EnqueueCopyService)
       .to receive(:new)
             .with(user: admin, model: project)
             .and_return(copy_service)

      allow(copy_service)
        .to receive(:call)
            .with(target_project_params: { "name" => name }, only: [], send_notifications: false)
            .and_return(service_result)

      post :copy, params: {
        id: project.identifier,
        project: { name: },
        copy_options: { dependencies: [""], send_notifications: false } # emulating empty dependencies array
      }
    end

    context "when service call succeeds" do
      let(:name) { "Copied project" }
      let(:job) { CopyProjectJob.new }
      let(:service_result) { ServiceResult.success(result: job) }

      it "redirects to job status" do
        expect(response).to redirect_to job_status_path(job.job_id)
      end
    end

    context "when service call fails" do
      let(:name) { "" }
      let(:target_project) { Project.new }
      let(:service_result) { ServiceResult.failure(result: target_project, message: "") }

      it "renders copy_form template with errors", :aggregate_failures do
        expect(response).not_to be_successful
        expect(response).to have_http_status :unprocessable_entity
        expect(assigns(:target_project)).to be_a_new(Project)
        expect(assigns(:target_project)).not_to be_valid
        expect(assigns(:project)).to eq project
        expect(assigns(:copy_options)).not_to be_nil
        expect(flash[:error]).to start_with I18n.t(:notice_unsuccessful_create_with_reason, reason: "")
        expect(response).to render_template "copy_form"
      end
    end
  end
end
