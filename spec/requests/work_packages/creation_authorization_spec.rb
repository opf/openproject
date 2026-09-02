# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Work package creation authorization", type: :rails_request do
  let(:project) { create(:project) }
  let(:creation_paths) do
    [
      new_work_package_path,
      new_split_work_packages_path,
      new_project_work_packages_path(project),
      new_split_project_work_packages_path(project)
    ]
  end
  let(:full_page_creation_paths) do
    [
      new_work_package_path,
      new_project_work_packages_path(project)
    ]
  end

  context "when signed in without permission to add work packages" do
    let(:role) { create(:project_role, permissions: %i[view_work_packages]) }
    let(:user) { create(:user, member_with_roles: { project => role }) }

    before { login_as(user) }

    it "forbids the full-page creation routes" do
      full_page_creation_paths.each do |path|
        get path

        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  context "when anonymous" do
    it "redirects every creation route to sign in" do
      creation_paths.each do |path|
        get path

        expect(response).to have_http_status(:found)
        expect(response.location).to start_with("http://test.host#{signin_path}?back_url=")

        follow_redirect!
        expect(response).to have_http_status(:ok)
        expect(response.body).to include(I18n.t(:label_login))
      end
    end
  end
end
