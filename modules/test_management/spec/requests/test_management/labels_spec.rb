# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Test management labels in project settings", :skip_csrf, type: :rails_request do
  shared_let(:project) { create(:project, enabled_module_names: %i[test_management]) }
  shared_let(:admin_member) do
    create(:user, member_with_permissions: { project => %i[view_test_cases manage_test_management] })
  end
  shared_let(:viewer) { create(:user, member_with_permissions: { project => %i[view_test_cases] }) }

  let(:current_user) { admin_member }
  let(:settings_path) { project_test_management_project_settings_path(project, anchor: "tm-labels") }

  before { login_as(current_user) }

  it "lists labels with their usage on the settings page" do
    label = create(:tm_label, project:, name: "smoke")
    create(:tm_test_case_label, test_case: create(:tm_test_case, project:), label:)

    get project_test_management_project_settings_path(project)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("tm-label-row-#{label.id}", "smoke", "1 case", "tm-label-new")
  end

  it "creates a label with a normalized name" do
    post project_test_management_labels_path(project), params: { label: { name: "  regression   suite ", color: "danger" } }

    expect(response).to redirect_to(settings_path)
    expect(TestManagement::Label.find_by(project:, name: "regression suite").color).to eq("danger")
  end

  it "refuses duplicate names" do
    create(:tm_label, project:, name: "smoke")

    post project_test_management_labels_path(project), params: { label: { name: "Smoke" } }

    expect(flash[:error]).to be_present
    expect(TestManagement::Label.where(project:).count).to eq(1)
  end

  it "renames a label and changes its color" do
    label = create(:tm_label, project:, name: "smoke", color: "accent")

    patch project_test_management_label_path(project, label), params: { label: { name: "sanity", color: "success" } }

    expect(response).to redirect_to(settings_path)
    expect(label.reload).to have_attributes(name: "sanity", color: "success")
  end

  it "deletes a label and removes it from its cases" do
    label = create(:tm_label, project:)
    create(:tm_test_case_label, test_case: create(:tm_test_case, project:), label:)

    delete project_test_management_label_path(project, label)

    expect(response).to redirect_to(settings_path)
    expect(TestManagement::Label.exists?(label.id)).to be(false)
    expect(TestManagement::TestCaseLabel.where(label_id: label.id)).to be_empty
  end

  it "answers 404 for a label of another project" do
    foreign = create(:tm_label)

    patch project_test_management_label_path(project, foreign), params: { label: { name: "x" } }

    expect(response).to have_http_status(:not_found)
  end

  context "without manage_test_management" do
    let(:current_user) { viewer }

    it "forbids changes" do
      label = create(:tm_label, project:, name: "smoke")

      post project_test_management_labels_path(project), params: { label: { name: "new" } }
      expect(response).to have_http_status(:forbidden)

      delete project_test_management_label_path(project, label)
      expect(response).to have_http_status(:forbidden)
      expect(TestManagement::Label.exists?(label.id)).to be(true)
    end
  end
end
