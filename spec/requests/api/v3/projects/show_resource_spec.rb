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

RSpec.describe "API v3 Project resource show", content_type: :json do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  let(:admin) { create(:admin) }
  let(:project) do
    create(:project,
           :with_status,
           public: false,
           active: project_active)
  end
  let(:project_active) { true }
  let(:other_project) do
    create(:project, public: false)
  end
  let(:permissions) { %i(view_project_attributes) }
  let(:role) { create(:project_role, permissions:) }
  let(:custom_field) do
    create(:text_project_custom_field)
  end
  let(:custom_value) do
    CustomValue.create(custom_field:,
                       value: "1234",
                       customized: project)
  end
  let(:invisible_custom_field) do
    create(:text_project_custom_field, admin_only: true)
  end
  let(:invisible_custom_value) do
    CustomValue.create(custom_field: invisible_custom_field,
                       value: "1234",
                       customized: project)
  end

  let(:get_path) { api_v3_paths.project project.id }
  let!(:parent_project) do
    create(:project, public: false).tap do |p|
      project.parent = p
      project.save!
    end
  end
  let!(:parent_memberships) do
    create(:member,
           user: current_user,
           project: parent_project,
           roles: [create(:project_role, permissions: [])])
  end

  current_user { create(:user, member_with_roles: { project => role }) }

  subject(:response) do
    get get_path

    last_response
  end

  context "for a logged in user" do
    it "responds with 200 OK" do
      expect(subject.status).to eq(200)
    end

    it "responds with the correct project" do
      expect(subject.body).to include_json("Project".to_json).at_path("_type")
      expect(subject.body).to be_json_eql(project.identifier.to_json).at_path("identifier")
    end

    it "links to the parent/ancestor project" do
      expect(subject.body)
        .to be_json_eql(api_v3_paths.project(parent_project.id).to_json)
              .at_path("_links/parent/href")

      expect(subject.body)
        .to be_json_eql(api_v3_paths.project(parent_project.id).to_json)
              .at_path("_links/ancestors/0/href")
    end

    it "includes only visible custom fields" do
      custom_value
      invisible_custom_value

      expect(subject.body)
        .to be_json_eql(custom_value.value.to_json)
              .at_path("customField#{custom_field.id}/raw")

      expect(subject.body)
        .not_to have_json_path("customField#{invisible_custom_field.id}/raw")
    end

    describe "permissions" do
      context "with admin permissions" do
        current_user { admin }

        it "includes invisible custom fields" do
          custom_value
          invisible_custom_value

          expect(subject.body)
            .to be_json_eql(custom_value.value.to_json)
                  .at_path("customField#{custom_field.id}/raw")

          expect(subject.body)
            .to be_json_eql(invisible_custom_value.value.to_json)
                  .at_path("customField#{invisible_custom_field.id}/raw")
        end
      end

      context "without view_project_attributes permission" do
        let(:permissions) { [] }

        it "does not include custom fields" do
          custom_value
          invisible_custom_value

          expect(subject.body)
            .not_to have_json_path("customField#{custom_field.id}/raw")
          expect(subject.body)
            .not_to have_json_path("customField#{invisible_custom_field.id}/raw")
        end
      end

      context "when requesting project without sufficient permissions" do
        let(:get_path) { api_v3_paths.project other_project.id }

        before do
          response
        end

        it_behaves_like "not found"
      end
    end

    it "includes the project status" do
      expect(subject.body)
        .to be_json_eql(project.status_explanation.to_json)
              .at_path("statusExplanation/raw")

      expect(subject.body)
        .to be_json_eql(api_v3_paths.project_status(project.status_code).to_json)
              .at_path("_links/status/href")
    end

    context "when requesting nonexistent project" do
      let(:get_path) { api_v3_paths.project 9999 }

      before do
        response
      end

      it_behaves_like "not found"
    end

    context "when not being allowed to see the parent project" do
      let!(:parent_memberships) do
        # no parent memberships
      end

      it "shows the `undisclosed` uri" do
        expect(subject.body)
          .to be_json_eql(API::V3::URN_UNDISCLOSED.to_json)
                .at_path("_links/parent/href")
      end
    end

    context "with the project being archived/inactive" do
      let(:project_active) { false }

      context "with the user being admin" do
        current_user { admin }

        it "responds with 200 OK" do
          expect(subject.status).to eq(200)
        end

        it "responds with the correct project" do
          expect(subject.body).to include_json("Project".to_json).at_path("_type")
          expect(subject.body).to be_json_eql(project.identifier.to_json).at_path("identifier")
        end
      end

      context "with the user being no admin" do
        it "responds with 404" do
          expect(subject.status).to eq(404)
        end
      end
    end
  end

  context "for a not logged in user" do
    current_user { create(:anonymous) }

    before do
      get get_path
    end

    it_behaves_like "not found response based on login_required"
  end
end
