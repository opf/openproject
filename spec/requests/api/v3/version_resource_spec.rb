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
require "rack/test"

RSpec.describe "API v3 Version resource", content_type: :json do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  let(:current_user) do
    create(:user, member_with_permissions: { project => permissions })
  end
  let(:permissions) { %i[view_work_packages manage_versions] }
  let(:project) { create(:project, public: false) }
  let(:other_project) { create(:project, public: false) }
  let!(:int_cf) { create(:version_custom_field, :integer) }
  let(:version_in_project) { build(:version, project:, custom_field_values: { int_cf.id => 123 }) }
  let(:version_in_other_project) do
    build(:version,
          project: other_project,
          sharing: "system",
          custom_field_values: { int_cf.id => 123 })
  end

  subject(:response) { last_response }

  describe "GET api/v3/versions/:id" do
    let(:get_path) { api_v3_paths.version version_in_project.id }

    shared_examples_for "successful response" do
      it "responds with 200" do
        expect(last_response).to have_http_status(:ok)
      end

      it "returns the version" do
        expect(last_response.body)
          .to be_json_eql("Version".to_json)
          .at_path("_type")

        expect(last_response.body)
          .to be_json_eql(expected_version.id.to_json)
          .at_path("id")

        expect(last_response.body)
          .to be_json_eql(123.to_json)
          .at_path("customField#{int_cf.id}")
      end
    end

    context "logged in user with permissions" do
      before do
        version_in_project.save!
        login_as current_user

        get get_path
      end

      it_behaves_like "successful response" do
        let(:expected_version) { version_in_project }
      end
    end

    context "logged in user with permission on project a version is shared with" do
      let(:get_path) { api_v3_paths.version version_in_other_project.id }

      before do
        version_in_other_project.save!
        login_as current_user

        get get_path
      end

      it_behaves_like "successful response" do
        let(:expected_version) { version_in_other_project }
      end
    end

    context "logged in user without permission" do
      let(:permissions) { [] }

      before do
        version_in_project.save!
        login_as current_user

        get get_path
      end

      it_behaves_like "not found"
    end
  end

  describe "PATCH api/v3/versions" do
    let(:path) { api_v3_paths.version(version.id) }
    let(:version) do
      create(:version,
             name: "Old name",
             description: "Old description",
             start_date: "2017-06-01",
             effective_date: "2017-07-01",
             status: "open",
             sharing: "none",
             project:,
             custom_field_values: { int_cf.id => 123,
                                    list_cf.id => list_cf.custom_options.first.id })
    end
    let!(:int_cf) { create(:version_custom_field, :integer) }
    let!(:list_cf) { create(:version_custom_field, :list) }
    let(:body) do
      {
        name: "New name",
        description: {
          raw: "New description"
        },
        "customField#{int_cf.id}": 5,
        startDate: "2018-01-01",
        endDate: "2018-01-09",
        status: "closed",
        sharing: "descendants",
        _links: {
          "customField#{list_cf.id}": {
            href: api_v3_paths.custom_option(list_cf.custom_options.last.id)
          }
        }
      }.to_json
    end

    before do
      login_as current_user

      patch path, body
    end

    it "responds with 200" do
      expect(last_response).to have_http_status(:ok)
    end

    it "updates the version" do
      expect(Version.find_by(name: "New name"))
        .to be_present
    end

    it "returns the updated version" do
      expect(last_response.body)
        .to be_json_eql("Version".to_json)
        .at_path("_type")

      expect(last_response.body)
        .to be_json_eql("New name".to_json)
        .at_path("name")

      expect(last_response.body)
        .to be_json_eql("<p>New description</p>".to_json)
        .at_path("description/html")

      expect(last_response.body)
        .to be_json_eql("2018-01-01".to_json)
        .at_path("startDate")

      expect(last_response.body)
        .to be_json_eql("2018-01-09".to_json)
        .at_path("endDate")

      expect(last_response.body)
        .to be_json_eql("closed".to_json)
        .at_path("status")

      expect(last_response.body)
        .to be_json_eql("descendants".to_json)
        .at_path("sharing")

      # unchanged
      expect(last_response.body)
        .to be_json_eql(project.name.to_json)
        .at_path("_links/definingProject/title")

      expect(last_response.body)
        .to be_json_eql(api_v3_paths.custom_option(list_cf.custom_options.last.id).to_json)
        .at_path("_links/customField#{list_cf.id}/href")

      expect(last_response.body)
        .to be_json_eql(5.to_json)
        .at_path("customField#{int_cf.id}")
    end

    context "if attempting to switch the project" do
      let(:other_project) do
        create(:project).tap do |p|
          create(:member,
                 project: p,
                 roles: [create(:project_role, permissions: [:manage_versions])],
                 user: current_user)
        end
      end

      let(:other_membership) do
      end
      let(:body) do
        {
          _links: {
            definingProject: {
              href: api_v3_paths.project(other_project.id)

            }
          }
        }.to_json
      end

      it_behaves_like "read-only violation", "project", Version
    end

    context "if lacking the manage permissions" do
      let(:permissions) { [:view_work_packages] }

      it_behaves_like "unauthorized access"
    end

    context "if lacking the manage permissions" do
      let(:permissions) { [] }

      it_behaves_like "not found"
    end

    context "if having the manage permission in a different project" do
      let(:other_membership) do
        create(:member,
               project: create(:project),
               roles: [create(:project_role, permissions: [:manage_versions])])
      end

      let(:permissions) do
        # load early
        other_membership

        [:view_work_packages]
      end

      it_behaves_like "unauthorized access"
    end
  end

  describe "POST api/v3/versions" do
    let(:path) { api_v3_paths.versions }
    let!(:int_cf) { create(:version_custom_field, :integer) }
    let!(:list_cf) { create(:version_custom_field, :list) }
    let(:body) do
      {
        name: "New version",
        description: {
          raw: "A new description"
        },
        "customField#{int_cf.id}": 5,
        startDate: "2018-01-01",
        endDate: "2018-01-09",
        status: "closed",
        sharing: "descendants",
        _links: {
          definingProject: {
            href: api_v3_paths.project(project.id)
          },
          "customField#{list_cf.id}": {
            href: api_v3_paths.custom_option(list_cf.custom_options.first.id)
          }
        }
      }.to_json
    end

    before do
      login_as current_user

      post path, body
    end

    it "responds with 201" do
      expect(last_response).to have_http_status(:created)
    end

    it "creates the version" do
      expect(Version.find_by(name: "New version"))
        .to be_present
    end

    it "returns the newly created version" do
      expect(last_response.body)
        .to be_json_eql("Version".to_json)
        .at_path("_type")

      expect(last_response.body)
        .to be_json_eql("New version".to_json)
        .at_path("name")

      expect(last_response.body)
        .to be_json_eql("<p>A new description</p>".to_json)
        .at_path("description/html")

      expect(last_response.body)
        .to be_json_eql("2018-01-01".to_json)
        .at_path("startDate")

      expect(last_response.body)
        .to be_json_eql("2018-01-09".to_json)
        .at_path("endDate")

      expect(last_response.body)
        .to be_json_eql("closed".to_json)
        .at_path("status")

      expect(last_response.body)
        .to be_json_eql("descendants".to_json)
        .at_path("sharing")

      expect(last_response.body)
        .to be_json_eql(project.name.to_json)
        .at_path("_links/definingProject/title")

      expect(last_response.body)
        .to be_json_eql(api_v3_paths.custom_option(list_cf.custom_options.first.id).to_json)
        .at_path("_links/customField#{list_cf.id}/href")

      expect(last_response.body)
        .to be_json_eql(5.to_json)
        .at_path("customField#{int_cf.id}")
    end

    context "if lacking the manage permissions" do
      let(:permissions) { [] }

      it_behaves_like "unauthorized access"
    end

    context "if having the manage permission in a different project" do
      let(:other_membership) do
        create(:member,
               project: create(:project),
               roles: [create(:project_role, permissions: [:manage_versions])])
      end

      let(:permissions) do
        # load early
        other_membership

        [:view_work_packages]
      end

      it_behaves_like "unauthorized access"
    end
  end

  describe "GET api/v3/versions" do
    let(:get_path) { api_v3_paths.versions }
    let(:response) { last_response }
    let(:versions) { [version_in_project] }

    before do
      versions.map(&:save!)
      login_as current_user

      get get_path
    end

    it "succeeds" do
      expect(last_response.status)
        .to be(200)
    end

    it_behaves_like "API V3 collection response", 1, 1, "Version"

    it "is the version the user has permission in" do
      expect(response.body)
        .to be_json_eql(api_v3_paths.version(version_in_project.id).to_json)
        .at_path("_embedded/elements/0/_links/self/href")
    end

    context "filtering for project by sharing" do
      let(:shared_version_in_project) do
        build(:version, project:, sharing: "system")
      end
      let(:versions) { [version_in_project, shared_version_in_project] }

      let(:filter_query) do
        [{ sharing: { operator: "=", values: ["system"] } }]
      end

      let(:get_path) do
        "#{api_v3_paths.versions}?filters=#{CGI.escape(JSON.dump(filter_query))}"
      end

      it_behaves_like "API V3 collection response", 1, 1, "Version"

      it "returns the shared version" do
        expect(response.body)
          .to be_json_eql(api_v3_paths.version(shared_version_in_project.id).to_json)
          .at_path("_embedded/elements/0/_links/self/href")
      end
    end
  end

  describe "DELETE /api/v3/versions/:id" do
    let(:path) { api_v3_paths.version(version.id) }
    let(:version) do
      create(:version,
             project:)
    end

    before do
      login_as current_user

      delete path
    end

    subject { last_response }

    context "with required permissions" do
      it "responds with HTTP No Content" do
        expect(subject.status).to eq 204
      end

      it "deletes the version" do
        expect(Version.exists?(version.id)).to be_falsey
      end

      context "for a non-existent version" do
        let(:path) { api_v3_paths.version 1337 }

        it_behaves_like "not found"
      end
    end

    context "with work packages attached to it" do
      let(:version) do
        create(:version,
               project:).tap do |v|
          create(:work_package,
                 project:,
                 version: v)
        end
      end

      it "returns a 422" do
        expect(subject.status)
          .to be 422
      end

      it "does not delete the version" do
        expect(Version.exists?(version.id)).to be_truthy
      end
    end

    context "without permission to see versions" do
      let(:permissions) { [] }

      it_behaves_like "not found"
    end

    context "without permission to delete versions" do
      let(:permissions) { [:view_work_packages] }

      it_behaves_like "unauthorized access"

      it "does not delete the version" do
        expect(Version.exists?(version.id)).to be_truthy
      end
    end
  end
end
