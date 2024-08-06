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

require "spec_helper"
require "rack/test"

RSpec.describe API::V3::Projects::Copy::CreateFormAPI, content_type: :json do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  shared_let(:text_custom_field) do
    create(:text_project_custom_field)
  end
  shared_let(:list_custom_field) do
    create(:list_project_custom_field)
  end

  shared_let(:source_project) do
    create(:project,
           custom_field_values: {
             text_custom_field.id => "source text",
             list_custom_field.id => list_custom_field.custom_options.last.id
           })
  end
  let(:permissions) { %i(copy_projects view_project view_work_packages view_project_attributes) }
  let(:current_user) do
    create(:user,
           member_with_permissions: { source_project => permissions })
  end

  let(:path) { api_v3_paths.project_copy_form(source_project.id) }
  let(:params) do
    {}
  end

  before do
    login_as(current_user)

    post path, params.to_json
  end

  subject(:response) { last_response }

  it "returns 200 FORM response", :aggregate_failures do
    expect(response).to have_http_status(:ok)

    expect(response.body)
      .to be_json_eql("Form".to_json)
            .at_path("_type")

    expect(Project.count)
      .to be 1
  end

  it "retains the values from the source project" do
    expect(response.body)
      .to be_json_eql("source text".to_json)
            .at_path("_embedded/payload/customField#{text_custom_field.id}/raw")

    expect(response.body)
      .to be_json_eql(list_custom_field.custom_options.last.value.to_json)
            .at_path("_embedded/payload/_links/customField#{list_custom_field.id}/title")
  end

  context "without view_project_attributes permission" do
    let(:permissions) { %i(copy_projects view_project view_work_packages) }

    it "does not activates custom fields from the source project" do
      expect(response.body)
        .not_to have_json_path("_embedded/payload/customField#{text_custom_field.id}")
    end
  end

  it "contains a meta property with copy properties for every module" do
    Projects::CopyService.copyable_dependencies.each do |dep|
      identifier = dep[:identifier].to_s.camelize
      expect(response.body)
        .to be_json_eql(true.to_json)
              .at_path("_embedded/payload/_meta/copy#{identifier}")
    end
  end

  it "shows an empty name as not set" do
    expect(response.body)
      .to be_json_eql("".to_json)
            .at_path("_embedded/payload/name")

    expect(response.body)
      .to be_json_eql("Name can't be blank.".to_json)
            .at_path("_embedded/validationErrors/name/message")
  end

  context "updating the form payload" do
    let(:params) do
      {
        name: "My copied project",
        identifier: "foobar",
        text_custom_field.attribute_name(:camel_case) => {
          raw: "CF text"
        },
        statusExplanation: { raw: "A magic dwells in each beginning." },
        _links: {
          list_custom_field.attribute_name(:camel_case) => {
            href: api_v3_paths.custom_option(list_custom_field.custom_options.first.id)
          },
          status: {
            href: api_v3_paths.project_status("on_track")
          }
        }
      }
    end

    it "sets those values" do
      expect(response.body)
        .to be_json_eql("My copied project".to_json)
              .at_path("_embedded/payload/name")

      expect(response.body)
        .to be_json_eql("foobar".to_json)
              .at_path("_embedded/payload/identifier")

      expect(response.body)
        .to be_json_eql(api_v3_paths.project_status("on_track").to_json)
              .at_path("_embedded/payload/_links/status/href")

      expect(response.body)
        .to be_json_eql("A magic dwells in each beginning.".to_json)
              .at_path("_embedded/payload/statusExplanation/raw")

      expect(response.body)
        .to be_json_eql("CF text".to_json)
              .at_path("_embedded/payload/customField#{text_custom_field.id}/raw")

      expect(response.body)
        .to be_json_eql(list_custom_field.custom_options.first.value.to_json)
              .at_path("_embedded/payload/_links/customField#{list_custom_field.id}/title")

      expect(response.body)
        .to be_json_eql({}.to_json)
              .at_path("_embedded/validationErrors")

      expect(response.body)
        .to be_json_eql("/api/v3/projects/#{source_project.id}/copy".to_json)
              .at_path("_links/commit/href")

      expect(response.body)
        .to be_json_eql("/api/v3/projects/#{source_project.id}/copy/form".to_json)
              .at_path("_links/validate/href")

      expect(response.body)
        .to be_json_eql("/api/v3/projects/#{source_project.id}/copy/form".to_json)
              .at_path("_links/self/href")
    end
  end

  context "when setting copy meta properties" do
    let(:params) do
      {
        _meta: {
          copyOverview: true
        }
      }
    end

    it "sets all values to true" do
      Projects::CopyService.copyable_dependencies.each do |dep|
        identifier = dep[:identifier].to_s.camelize
        expect(response.body)
          .to be_json_eql(true.to_json)
                .at_path("_embedded/payload/_meta/copy#{identifier}")
      end
    end
  end

  describe "send_notification" do
    context "when not present" do
      let(:params) do
        {}
      end

      it "returns it as false" do
        expect(response.body)
          .to be_json_eql(false.to_json)
                .at_path("_embedded/payload/_meta/sendNotifications")
      end
    end

    context "when set to false" do
      let(:params) do
        {
          _meta: {
            sendNotifications: false
          }
        }
      end

      it "returns it as false" do
        expect(response.body)
          .to be_json_eql(false.to_json)
                .at_path("_embedded/payload/_meta/sendNotifications")
      end
    end

    context "when set to true" do
      let(:params) do
        {
          _meta: {
            sendNotifications: true
          }
        }
      end

      it "returns it as true" do
        expect(response.body)
          .to be_json_eql(true.to_json)
                .at_path("_embedded/payload/_meta/sendNotifications")
      end
    end
  end

  context "without the necessary permission" do
    let(:current_user) do
      create(:user,
             member_with_permissions: { source_project => %i[view_project view_work_packages] })
    end

    it "returns 403 Not Authorized" do
      expect(response).to have_http_status(:forbidden)
    end
  end
end
