# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Test run attachments", :skip_csrf, type: :rails_request do
  include FileHelpers

  shared_let(:project) { create(:project, enabled_module_names: %i[test_management]) }
  shared_let(:manager) do
    create(:user, member_with_permissions: { project => %i[view_test_cases view_test_runs add_test_runs execute_test_runs] })
  end
  shared_let(:tester) do
    create(:user, member_with_permissions: { project => %i[view_test_cases view_test_runs execute_test_runs] })
  end
  shared_let(:viewer) { create(:user, member_with_permissions: { project => %i[view_test_cases view_test_runs] }) }

  let(:run) { create(:tm_test_run, :in_progress, project:) }
  let(:run_case) { create(:tm_test_run_case, test_run: run) }
  let(:current_user) { manager }
  let(:file) { mock_uploaded_file(name: "screenshot.png", content_type: "image/png", content: "png") }

  before { login_as(current_user) }

  def upload_to_case(params = { file: })
    post project_test_management_test_run_run_case_attachments_path(project, run, run_case), params:
  end

  describe "run case attachments" do
    it "uploads a file and redirects to the run case" do
      upload_to_case

      expect(response).to redirect_to(project_test_management_test_run_path(project, run, anchor: "run-case-#{run_case.id}"))
      expect(run_case.attachments.map(&:filename)).to eq(["screenshot.png"])
      expect(flash[:notice]).to eq(I18n.t("test_management.runs.attachments.uploaded"))
    end

    it "shows an error without a file" do
      upload_to_case({})

      expect(response).to have_http_status(:see_other)
      expect(flash[:error]).to eq(I18n.t("test_management.runs.attachments.missing_file"))
    end

    it "deletes an attachment through Attachments::DeleteService" do
      attachment = create(:attachment, container: run_case, author: manager)
      allow(Attachments::DeleteService).to receive(:new).and_call_original

      delete project_test_management_test_run_run_case_attachment_path(project, run, run_case, attachment)

      expect(response).to have_http_status(:see_other)
      expect(Attachment.exists?(attachment.id)).to be(false)
      expect(Attachments::DeleteService).to have_received(:new).with(user: manager, model: attachment)
    end

    it "does not show internal exception messages" do
      allow(Attachments::CreateService).to receive(:new).and_raise(StandardError, "PG::Error at /var/openproject/assets/secret")

      upload_to_case

      expect(response).to have_http_status(:see_other)
      expect(flash[:error]).not_to include("/var/openproject")
      expect(flash[:error]).to include(I18n.t("test_management.runs.attachments.unexpected_error"))
    end

    context "as a tester" do
      let(:current_user) { tester }

      it "may attach evidence to a run case" do
        upload_to_case

        expect(run_case.attachments.count).to eq(1)
      end

      it "may not attach files to the run itself" do
        post project_test_management_test_run_attachments_path(project, run), params: { file: }

        expect(response).to have_http_status(:forbidden)
        expect(run.attachments).to be_empty
      end
    end

    context "as a viewer" do
      let(:current_user) { viewer }

      it "is forbidden" do
        upload_to_case

        expect(response).to have_http_status(:forbidden)
        expect(run_case.attachments).to be_empty
      end
    end

    context "on a finished run" do
      let(:run) { create(:tm_test_run, :completed, project:) }

      it "refuses uploads and deletions" do
        attachment = create(:attachment, container: run_case, author: manager)

        upload_to_case
        expect(response).to have_http_status(:forbidden)

        delete project_test_management_test_run_run_case_attachment_path(project, run, run_case, attachment)
        expect(response).to have_http_status(:forbidden)
        expect(Attachment.exists?(attachment.id)).to be(true)
      end
    end

    it "answers 404 for a run case of another run" do
      other_case = create(:tm_test_run_case, test_run: create(:tm_test_run, project:))

      post project_test_management_test_run_run_case_attachments_path(project, run, other_case), params: { file: }

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "run attachments" do
    it "uploads to the run and redirects to the attachments section" do
      post project_test_management_test_run_attachments_path(project, run), params: { file: }

      expect(response).to redirect_to(project_test_management_test_run_path(project, run, anchor: "run-attachments"))
      expect(run.attachments.map(&:filename)).to eq(["screenshot.png"])
    end
  end

  describe "the run page" do
    it "lists attachments with upload forms" do
      create(:attachment, container: run_case, author: manager, filename: "trace.zip")

      get project_test_management_test_run_path(project, run)

      expect(response.body).to include("trace.zip", "tm-attachments--form", 'id="run-attachments"')
    end
  end
end
