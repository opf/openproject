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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"
require "rack/test"

RSpec.describe API::V3::Activities::ActivitiesByWorkPackageAPI, with_ee: [:internal_comments] do # rubocop:disable RSpec/SpecFilePathFormat
  include API::V3::Utilities::PathHelper

  describe "activities" do
    let(:project) { work_package.project }
    let(:work_package) { create(:work_package) }
    let(:comment) { "This is a test comment!" }
    let(:current_user) do
      create(:user, member_with_roles: { project => role })
    end
    let(:admin) { create(:admin) }
    let(:role) { create(:project_role, permissions:) }
    let(:permissions) do
      %i(view_work_packages add_work_package_comments view_internal_comments)
    end

    before do
      allow(User).to receive(:current).and_return(current_user)
    end

    describe "GET /api/v3/work_packages/:id/activities" do
      context "when activities do not include internal journals" do
        before do
          get api_v3_paths.work_package_activities work_package.id
        end

        it "succeeds" do
          expect(last_response).to have_http_status :ok
        end

        context "when not allowed to see work package" do
          let(:current_user) { create(:user) }

          it "fails with HTTP Not Found" do
            expect(last_response).to have_http_status :not_found
          end
        end
      end

      context "when activities include internal journals" do
        let!(:internal_note) do
          create(:work_package_journal,
                 journable: work_package,
                 user: admin,
                 notes: "Internal comment",
                 internal: true,
                 version: 2)
        end

        before do
          project.enabled_internal_comments = true
          project.save!
        end

        context "and user has the permission to see it" do
          it "includes internal activities" do
            get api_v3_paths.work_package_activities work_package.id
            expect(last_response.body).to include("Internal comment")
          end
        end

        context "and user does not have the permission to see it" do
          before do
            role.role_permissions
              .find_by(permission: "view_internal_comments")
              .destroy
          end

          it "does not include internal activities" do
            get api_v3_paths.work_package_activities work_package.id
            expect(last_response.body).not_to include("Internal comment")
          end
        end
      end
    end

    describe "POST /api/v3/work_packages/:id/activities" do
      let(:work_package) { create(:work_package) }

      shared_context "create activity" do # rubocop:disable RSpec/ContextWording
        before do
          header "Content-Type", "application/json"
          post api_v3_paths.work_package_activities(work_package.id),
               { comment: { raw: comment } }.to_json
        end
      end

      it_behaves_like "safeguarded API" do
        let(:permissions) { %i(view_work_packages) }

        include_context "create activity"
      end

      it_behaves_like "valid activity request" do
        let(:status_code) { 201 }

        include_context "create activity"
      end

      context "with an erroneous work package" do
        before do
          work_package.done_ratio = -100
          work_package.save!(validate: false)
        end

        it_behaves_like "valid activity request" do
          let(:status_code) { 201 }

          include_context "create activity"
        end
      end

      context "when creating an internal comment" do
        shared_context "to create internal comment" do |internal: false, enabled_internal_comments: true|
          before do
            work_package.project.update!(enabled_internal_comments:)
            header "Content-Type", "application/json"
            post api_v3_paths.work_package_activities(work_package.id),
                 { comment: { raw: comment }, internal: }.to_json
          end
        end

        context "and the user has the permission to create internal comments" do
          it_behaves_like "valid activity request" do
            let(:permissions) { %i(view_work_packages view_internal_comments add_internal_comments) }
            let(:status_code) { 201 }

            include_context "to create internal comment", internal: true

            it "creates an internal comment" do
              expect(last_response.body).to be_json_eql(true.to_json).at_path("internal")
            end
          end

          it_behaves_like "valid activity request" do
            let(:permissions) { %i(view_work_packages view_internal_comments add_internal_comments) }
            let(:status_code) { 201 }

            include_context "to create internal comment", internal: false

            it "creates an internal comment" do
              expect(last_response.body).to be_json_eql(false.to_json).at_path("internal")
            end
          end

          it_behaves_like "valid activity request" do
            let(:permissions) { %i(view_work_packages view_internal_comments add_internal_comments) }
            let(:status_code) { 201 }

            include_context "to create internal comment", internal: nil

            it "creates an internal comment" do
              expect(last_response.body).to be_json_eql(false.to_json).at_path("internal")
            end
          end
        end

        context "and the user does not have the permission to create internal comments" do
          let(:permissions) { %i(view_work_packages add_work_package_comments view_internal_comments) }

          include_context "to create internal comment", internal: true

          it "fails with HTTP Unprocessable Entity" do
            expect(last_response).to have_http_status :unprocessable_entity
          end

          it "notes the error" do
            expect(last_response.body)
              .to be_json_eql("Internal Journal may not be accessed.".to_json)
              .at_path("message")
          end
        end

        context "and internal comments are disabled on the project" do
          let(:permissions) { %i(view_work_packages add_work_package_comments view_internal_comments add_internal_comments) }

          include_context "to create internal comment", internal: true, enabled_internal_comments: false

          it "fails with HTTP Unprocessable Entity" do
            expect(last_response).to have_http_status :unprocessable_entity
          end

          it "notes the error" do
            expect(last_response.body)
              .to be_json_eql("Internal Journal is disabled for this project.".to_json)
              .at_path("message")
          end
        end
      end

      context "with attachments" do
        include_context "create activity"

        let(:attachment1) { create(:attachment, container: nil, author: current_user) }
        let(:attachment2) { create(:attachment, container: nil, author: current_user) }

        let(:comment) do
          <<~HTML
            <img class="op-uc-image op-uc-image_inline" src="/api/v3/attachments/#{attachment1.id}/content">
            Lorem ipsum dolor sit amet
            <img class="op-uc-image op-uc-image_inline" src="/api/v3/attachments/#{attachment2.id}/content">
            consectetur adipiscing elit
          HTML
        end

        it "creates attachment claims" do
          expect(last_response.body).to be_json_eql(comment.to_json).at_path("comment/raw")
          journal = work_package.journals.last
          expect(journal.attachments).to contain_exactly(attachment1, attachment2)
        end
      end
    end
  end
end
