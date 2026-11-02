# frozen_string_literal: true

require "spec_helper"
require "rack/test"

# The Angular "Testing" tab is displayable only when the work package
# representer carries `_links.testing`.
RSpec.describe "APIv3 work package _links.testing" do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  shared_let(:project) { create(:project, enabled_module_names: %i[test_management work_package_tracking]) }
  shared_let(:plain_project) { create(:project, enabled_module_names: %i[work_package_tracking]) }
  shared_let(:work_package) { create(:work_package, project:) }
  shared_let(:plain_work_package) { create(:work_package, project: plain_project) }
  shared_let(:tester) do
    create(:user,
           member_with_permissions: {
             project => %i[view_work_packages view_test_cases show_testing_content],
             plain_project => %i[view_work_packages]
           })
  end
  shared_let(:reader) { create(:user, member_with_permissions: { project => %i[view_work_packages view_test_cases] }) }

  def links = JSON.parse(last_response.body)["_links"]

  context "with show_testing_content in a project with the module" do
    before { login_as(tester) }

    it "links the Testing tab" do
      get api_v3_paths.work_package(work_package.id)

      expect(last_response).to have_http_status(200)
      expect(links["testing"]).to include("href" => "/work_packages/#{work_package.id}/tabs/testing", "title" => "testing")
    end

    it "has no link where the module is not enabled" do
      get api_v3_paths.work_package(plain_work_package.id)

      expect(last_response).to have_http_status(200)
      expect(links).not_to have_key("testing")
    end
  end

  context "without show_testing_content" do
    before { login_as(reader) }

    it "has no link" do
      get api_v3_paths.work_package(work_package.id)

      expect(last_response).to have_http_status(200)
      expect(links).not_to have_key("testing")
    end
  end
end
