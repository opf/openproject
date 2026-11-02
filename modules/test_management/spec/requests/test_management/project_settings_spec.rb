# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Test management project settings", :skip_csrf, type: :rails_request do
  shared_let(:project) { create(:project, enabled_module_names: %i[test_management]) }

  describe "PATCH /projects/:id/test_management/project_settings" do
    context "with manage_test_management" do
      let(:user) do
        create(:user,
               member_with_permissions: {
                 project => %i[view_test_cases manage_test_management]
               })
      end

      before { login_as(user) }

      it "updates folder tree layout" do
        patch project_test_management_project_settings_path(project),
              params: {
                project_setting: {
                  folder_tree_layout: "sidebar",
                  display_prefix: "TC"
                }
              }

        expect(response).to redirect_to(project_test_management_project_settings_path(project))
        setting = TestManagement::ProjectSetting.find_by!(project:)
        expect(setting.folder_tree_layout).to eq("sidebar")
      end
    end

    context "without manage_test_management" do
      let(:user) do
        create(:user, member_with_permissions: { project => %i[view_test_cases] })
      end

      before { login_as(user) }

      it "forbids update" do
        patch project_test_management_project_settings_path(project),
              params: { project_setting: { folder_tree_layout: "sidebar" } }

        expect(response).to have_http_status(:forbidden)
        expect(TestManagement::ProjectSetting.find_by(project:)&.folder_tree_layout)
          .not_to eq("sidebar")
      end
    end

    context "with manage_test_ci only" do
      let(:user) do
        create(:user, member_with_permissions: {
                 project => %i[view_test_cases manage_test_ci]
               })
      end

      before { login_as(user) }

      it "shows CI settings without the general form" do
        get project_test_management_project_settings_path(project)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("tm-ci-connections")
        expect(response.body).not_to include('data-test-selector="tm-project-settings-form"')
        expect(response.body).not_to include('data-test-selector="tm-project-settings-save"')
      end

      it "forbids general settings update" do
        patch project_test_management_project_settings_path(project),
              params: { project_setting: { folder_tree_layout: "sidebar", display_prefix: "XX" } }

        expect(response).to have_http_status(:forbidden)
        expect(TestManagement::ProjectSetting.find_by(project:)&.display_prefix).not_to eq("XX")
      end
    end
  end
end
