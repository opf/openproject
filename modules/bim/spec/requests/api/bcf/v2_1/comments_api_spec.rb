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

require_relative "shared_responses"

RSpec.describe "BCF 2.1 comments resource", content_type: :json do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  let(:project) do
    create(:project, enabled_module_names: %i[bim work_package_tracking])
  end

  let(:view_only_user) do
    create(:user,
           member_with_permissions: { project => %i[view_linked_issues view_work_packages] })
  end

  let(:edit_user) do
    create(:user,
           member_with_permissions: { project => %i[view_linked_issues view_work_packages manage_bcf] })
  end

  let(:user_without_permission) do
    create(:user, member_with_permissions: { project => %i[view_work_packages edit_work_packages] })
  end

  let(:assignee) { create(:user) }

  let(:work_package) do
    create(:work_package, assigned_to: assignee, due_date: Time.zone.today, project:)
  end

  let(:bcf_issue) { create(:bcf_issue_with_viewpoint, work_package:) }
  let(:viewpoint) { bcf_issue.viewpoints.first }

  let(:bcf_comment) { create(:bcf_comment, issue: bcf_issue, author: view_only_user) }
  let(:bcf_answer) { create(:bcf_comment, issue: bcf_issue, reply_to: bcf_comment, author: assignee) }
  let(:bcf_comment_to_viewpoint) do
    create(:bcf_comment, issue: bcf_issue, viewpoint:, author: edit_user)
  end

  subject(:response) { last_response }

  describe "GET /api/bcf/2.1/projects/:project_id/topics/:topic_guid/comments" do
    let(:path) { "/api/bcf/2.1/projects/#{project.id}/topics/#{bcf_issue.uuid}/comments" }
    let(:current_user) { view_only_user }
    let(:comments) { bcf_comment }

    before do
      login_as(current_user)
      comments
      get path
    end

    it_behaves_like "bcf api successful response" do
      let(:comments) { [bcf_comment, bcf_answer, bcf_comment_to_viewpoint] }

      let(:expected_body) do
        [
          {
            guid: bcf_comment.uuid,
            date: bcf_comment.journal.created_at,
            author: view_only_user.mail,
            comment: bcf_comment.journal.notes,
            modified_date: bcf_comment.journal.updated_at,
            modified_author: view_only_user.mail,
            topic_guid: bcf_issue.uuid,
            reply_to_comment_guid: nil,
            viewpoint_guid: nil,
            authorization: {
              comment_actions: []
            }
          },
          {
            guid: bcf_answer.uuid,
            date: bcf_answer.journal.created_at,
            author: assignee.mail,
            comment: bcf_answer.journal.notes,
            modified_date: bcf_answer.journal.updated_at,
            modified_author: assignee.mail,
            topic_guid: bcf_issue.uuid,
            reply_to_comment_guid: bcf_comment.uuid,
            viewpoint_guid: nil,
            authorization: {
              comment_actions: []
            }
          },
          {
            guid: bcf_comment_to_viewpoint.uuid,
            date: bcf_comment_to_viewpoint.journal.created_at,
            author: edit_user.mail,
            comment: bcf_comment_to_viewpoint.journal.notes,
            modified_date: bcf_comment_to_viewpoint.journal.updated_at,
            modified_author: edit_user.mail,
            topic_guid: bcf_issue.uuid,
            reply_to_comment_guid: nil,
            viewpoint_guid: viewpoint.uuid,
            authorization: {
              comment_actions: []
            }
          }
        ]
      end
    end

    context "with edit comments permission" do
      let(:current_user) { edit_user }

      it_behaves_like "bcf api successful response" do
        let(:expected_body) do
          [
            {
              guid: bcf_comment.uuid,
              date: bcf_comment.journal.created_at,
              author: view_only_user.mail,
              comment: bcf_comment.journal.notes,
              modified_date: bcf_comment.journal.updated_at,
              modified_author: view_only_user.mail,
              topic_guid: bcf_issue.uuid,
              reply_to_comment_guid: nil,
              viewpoint_guid: nil,
              authorization: {
                comment_actions: [
                  "update"
                ]
              }
            }
          ]
        end
      end
    end

    context "without view permissions" do
      let(:current_user) { user_without_permission }

      it_behaves_like "bcf api not allowed response"
    end
  end

  describe "POST /api/bcf/2.1/projects/:project_id/topics/:topic_guid/comments" do
    let(:path) { "/api/bcf/2.1/projects/#{project.id}/topics/#{bcf_issue.uuid}/comments" }
    let(:current_user) { edit_user }
    let(:params) do
      {
        comment: "this is a new bcf comment"
      }
    end

    before do
      login_as(current_user)
      post path, params.to_json
    end

    it_behaves_like "bcf api successful response" do
      let(:expected_status) { 201 }
      let(:expected_body) do
        comment = Bim::Bcf::Comment.last.reload

        {
          guid: comment&.uuid,
          date: comment&.journal&.created_at&.iso8601,
          author: edit_user.mail,
          comment: "this is a new bcf comment",
          modified_date: comment&.journal&.updated_at&.iso8601,
          modified_author: edit_user.mail,
          topic_guid: bcf_issue.uuid,
          reply_to_comment_guid: nil,
          viewpoint_guid: nil,
          authorization: {
            comment_actions: [
              "update"
            ]
          }
        }
      end
    end

    context "if user has no permission to write comments" do
      let(:current_user) { view_only_user }

      it_behaves_like "bcf api not allowed response"
    end

    context "if request contains viewpoint guid" do
      let(:params) do
        {
          comment: "this is a comment to a specific viewpoint",
          viewpoint_guid: viewpoint.uuid
        }
      end

      it_behaves_like "bcf api successful response" do
        let(:expected_status) { 201 }
        let(:expected_body) do
          comment = Bim::Bcf::Comment.last.reload

          {
            guid: comment&.uuid,
            date: comment&.journal&.created_at,
            author: edit_user.mail,
            comment: "this is a comment to a specific viewpoint",
            modified_date: comment&.journal&.updated_at,
            modified_author: edit_user.mail,
            topic_guid: bcf_issue.uuid,
            reply_to_comment_guid: nil,
            viewpoint_guid: viewpoint.uuid,
            authorization: {
              comment_actions: [
                "update"
              ]
            }
          }
        end
      end

      context "if the viewpoint guid does not exist" do
        let(:params) do
          {
            comment: "this is a comment to a specific viewpoint",
            viewpoint_guid: "00000000-0000-0000-0000-000000000000"
          }
        end

        it_behaves_like "bcf api unprocessable response" do
          let(:message) { "Viewpoint does not exist." }
        end
      end
    end

    context "if request contains reply comment" do
      let(:params) do
        {
          comment: "this is a reply comment to another comment",
          reply_to_comment_guid: bcf_comment.uuid
        }
      end

      it_behaves_like "bcf api successful response" do
        let(:expected_status) { 201 }
        let(:expected_body) do
          comment = Bim::Bcf::Comment.last.reload

          {
            guid: comment&.uuid,
            date: comment&.journal&.created_at,
            author: edit_user.mail,
            comment: "this is a reply comment to another comment",
            modified_date: comment&.journal&.updated_at,
            modified_author: edit_user.mail,
            topic_guid: bcf_issue.uuid,
            reply_to_comment_guid: bcf_comment.uuid,
            viewpoint_guid: nil,
            authorization: {
              comment_actions: [
                "update"
              ]
            }
          }
        end
      end

      context "if the comment guid does not exist" do
        let(:params) do
          {
            comment: "this is a reply comment to another comment",
            reply_to_comment_guid: "00000000-0000-0000-0000-000000000000"
          }
        end

        it_behaves_like "bcf api unprocessable response" do
          let(:message) { "Bcf comment does not exist." }
        end
      end
    end

    context "if request contains reply comment and viewpoint reference" do
      let(:params) do
        {
          comment: "this is a reply comment to another comment with a specific reference to a viewpoint",
          reply_to_comment_guid: bcf_comment.uuid,
          viewpoint_guid: viewpoint.uuid
        }
      end

      it_behaves_like "bcf api successful response" do
        let(:expected_status) { 201 }
        let(:expected_body) do
          comment = Bim::Bcf::Comment.last.reload

          {
            guid: comment&.uuid,
            date: comment&.journal&.created_at,
            author: edit_user.mail,
            comment: "this is a reply comment to another comment with a specific reference to a viewpoint",
            modified_date: comment&.journal&.updated_at,
            modified_author: edit_user.mail,
            topic_guid: bcf_issue.uuid,
            reply_to_comment_guid: bcf_comment.uuid,
            viewpoint_guid: viewpoint.uuid,
            authorization: {
              comment_actions: [
                "update"
              ]
            }
          }
        end
      end

      context "if the comment guid does not exist" do
        let(:params) do
          {
            comment: "this is a reply comment to another comment",
            reply_to_comment_guid: "00000000-0000-0000-0000-000000000000",
            viewpoint_guid: viewpoint.uuid
          }
        end

        it_behaves_like "bcf api unprocessable response" do
          let(:message) { "Bcf comment does not exist." }
        end
      end

      context "if the viewpoint guid does not exist" do
        let(:params) do
          {
            comment: "this is a reply comment to another comment",
            viewpoint_guid: "00000000-0000-0000-0000-000000000000",
            reply_to_comment_guid: bcf_comment.uuid
          }
        end

        it_behaves_like "bcf api unprocessable response" do
          let(:message) { "Viewpoint does not exist." }
        end
      end

      context "if the comment and viewpoint guid does not exist" do
        let(:params) do
          {
            comment: "this is a reply comment to another comment",
            reply_to_comment_guid: "00000000-0000-0000-0000-000000000000",
            viewpoint_guid: "00000000-0000-0000-0000-000000000000"
          }
        end

        it_behaves_like "bcf api unprocessable response" do
          let(:message) { "Multiple field constraints have been violated. Viewpoint does not exist. Bcf comment does not exist." }
        end
      end
    end
  end

  describe "PUT /api/bcf/2.1/projects/:project_id/topics/:topic_guid/comments" do
    let(:path) { "/api/bcf/2.1/projects/#{project.id}/topics/#{bcf_issue.uuid}/comments" }
    let(:current_user) { edit_user }
    let(:params) { { comment: "This is a bad comment update ... " } }

    before do
      login_as(current_user)
      put path, params.to_json
    end

    it_behaves_like "bcf api method not allowed response"
  end

  describe "GET /api/bcf/2.1/projects/:project_id/topics/:topic_guid/comments/:comment_guid" do
    let(:path) { "/api/bcf/2.1/projects/#{project.id}/topics/#{bcf_issue.uuid}/comments/#{bcf_comment.uuid}" }
    let(:current_user) { view_only_user }
    let(:comments) { [bcf_comment, bcf_answer, bcf_comment_to_viewpoint] }

    before do
      login_as(current_user)
      comments
      get path
    end

    it_behaves_like "bcf api successful response" do
      let(:expected_body) do
        bcf_comment.reload

        {
          guid: bcf_comment.uuid,
          date: bcf_comment.journal.created_at,
          author: view_only_user.mail,
          comment: bcf_comment.journal.notes,
          modified_date: bcf_comment.journal.updated_at,
          modified_author: view_only_user.mail,
          topic_guid: bcf_issue.uuid,
          reply_to_comment_guid: nil,
          viewpoint_guid: nil,
          authorization: { comment_actions: [] }
        }
      end
    end

    context "if user has editing permissions" do
      let(:current_user) { edit_user }

      it_behaves_like "bcf api successful response" do
        let(:expected_body) do
          bcf_comment.reload

          {
            guid: bcf_comment.uuid,
            date: bcf_comment.journal.created_at,
            author: view_only_user.mail,
            comment: bcf_comment.journal.notes,
            modified_date: bcf_comment.journal.updated_at,
            modified_author: view_only_user.mail,
            topic_guid: bcf_issue.uuid,
            reply_to_comment_guid: nil,
            viewpoint_guid: nil,
            authorization: {
              comment_actions: [
                "update"
              ]
            }
          }
        end
      end
    end

    context "if comment id does not exist" do
      let(:invalid_id) { "1337" }
      let(:path) { "/api/bcf/2.1/projects/#{project.id}/topics/#{bcf_issue.uuid}/comments/#{invalid_id}" }

      it_behaves_like "bcf api not found response"
    end

    context "without view permissions" do
      let(:current_user) { user_without_permission }

      it_behaves_like "bcf api not allowed response"
    end
  end

  describe "PUT /api/bcf/2.1/projects/:project_id/topics/:topic_guid/comments/:comment_guid" do
    let(:updated_comment) { bcf_comment }
    let(:path) { "/api/bcf/2.1/projects/#{project.id}/topics/#{bcf_issue.uuid}/comments/#{updated_comment.uuid}" }
    let(:current_user) { edit_user }
    let(:params) { { comment: "Update comment to this elaborate text." } }

    before do
      login_as(current_user)
      put path, params.to_json
    end

    it_behaves_like "bcf api successful response" do
      let(:expected_body) do
        updated_comment.reload

        {
          guid: updated_comment.uuid,
          date: updated_comment.journal.created_at,
          author: view_only_user.mail,
          comment: "Update comment to this elaborate text.",
          modified_date: updated_comment.journal.updated_at,
          # we cannot store another author then the journal creator
          modified_author: view_only_user.mail,
          topic_guid: bcf_issue.uuid,
          reply_to_comment_guid: nil,
          viewpoint_guid: nil,
          authorization: {
            comment_actions: [
              "update"
            ]
          }
        }
      end
    end

    context "if user has no edit permissions" do
      let(:current_user) { view_only_user }

      it_behaves_like "bcf api not allowed response"
    end

    context "if viewpoint reference and reply to is changed" do
      let(:params) do
        {
          comment: "A new updated text",
          viewpoint_guid: viewpoint.uuid,
          reply_to_comment_guid: bcf_comment_to_viewpoint.uuid
        }
      end

      it_behaves_like "bcf api successful response" do
        let(:expected_body) do
          updated_comment.reload

          {
            guid: updated_comment.uuid,
            date: updated_comment.journal.created_at,
            author: view_only_user.mail,
            comment: "A new updated text",
            modified_date: updated_comment.journal.updated_at,
            # we cannot store another author then the journal creator
            modified_author: view_only_user.mail,
            topic_guid: bcf_issue.uuid,
            reply_to_comment_guid: bcf_comment_to_viewpoint.uuid,
            viewpoint_guid: viewpoint.uuid,
            authorization: {
              comment_actions: [
                "update"
              ]
            }
          }
        end
      end
    end

    context "if an invalid viewpoint guid is given" do
      let(:params) do
        {
          comment: "A new updated text",
          viewpoint_guid: "00000000-0000-0000-0000-000000000000"
        }
      end

      it_behaves_like "bcf api unprocessable response" do
        let(:message) { "Viewpoint does not exist." }
      end
    end

    context "if an invalid comment guid is given" do
      let(:params) do
        {
          comment: "A new updated text",
          reply_to_comment_guid: "00000000-0000-0000-0000-000000000000"
        }
      end

      it_behaves_like "bcf api unprocessable response" do
        let(:message) { "Bcf comment does not exist." }
      end
    end

    context "if the updated comment contains viewpoint reference and is a reply, but update does not set those attributes" do
      let(:updated_comment) do
        create(:bcf_comment,
               issue: bcf_issue,
               viewpoint:,
               reply_to: bcf_comment,
               author: edit_user)
      end

      let(:params) { { comment: "Only change the comment text and leave the reply and viewpoint guid empty." } }

      it_behaves_like "bcf api successful response" do
        let(:expected_body) do
          updated_comment.reload

          {
            guid: updated_comment.uuid,
            date: updated_comment.journal.created_at,
            author: edit_user.mail,
            comment: "Only change the comment text and leave the reply and viewpoint guid empty.",
            modified_date: updated_comment.journal.updated_at,
            # we cannot store another author then the journal creator
            modified_author: edit_user.mail,
            topic_guid: bcf_issue.uuid,
            reply_to_comment_guid: nil,
            viewpoint_guid: nil,
            authorization: {
              comment_actions: [
                "update"
              ]
            }
          }
        end
      end
    end
  end

  describe "POST /api/bcf/2.1/projects/:project_id/topics/:topic_guid/comments/:comment_guid" do
    let(:path) { "/api/bcf/2.1/projects/#{project.id}/topics/#{bcf_issue.uuid}/comments/#{bcf_comment.uuid}" }
    let(:current_user) { edit_user }
    let(:params) { { comment: "This is an invalid try to create a comment ..." } }

    before do
      login_as(current_user)
      post path, params.to_json
    end

    it_behaves_like "bcf api method not allowed response"
  end
end
