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

RSpec.describe "BCF 2.1 topics resource", content_type: :json do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  let(:view_only_user) do
    create(:user,
           member_with_permissions: { project => %i[view_linked_issues view_work_packages work_package_assigned] })
  end
  let(:only_member_user) do
    create(:user,
           member_with_permissions: { project => [] })
  end
  let(:edit_member_user) do
    create(:user,
           member_with_permissions: { project => %i[manage_bcf
                                                    add_work_packages
                                                    view_linked_issues
                                                    view_work_packages
                                                    edit_work_packages] })
  end
  let(:edit_and_delete_member_user) do
    create(:user,
           member_with_permissions: { project => %i[delete_bcf
                                                    delete_work_packages
                                                    manage_bcf
                                                    add_work_packages
                                                    view_linked_issues
                                                    view_work_packages] })
  end
  let(:edit_work_package_member_user) do
    create(:user,
           member_with_permissions: { project => %i[add_work_packages
                                                    view_linked_issues
                                                    edit_work_packages
                                                    view_work_packages] })
  end
  let(:non_member_user) do
    create(:user)
  end

  let(:project) do
    create(:project,
           enabled_module_names: %i[bim work_package_tracking])
  end
  let(:assignee) { create(:user) }
  let(:work_package) do
    create(:work_package,
           assigned_to: assignee,
           due_date: Date.today,
           project:)
  end
  let(:other_status) do
    create(:status).tap do |s|
      member = current_user.members.detect { |m| m.project_id == work_package.project_id }

      if member
        create(:workflow,
               old_status: work_package.status,
               new_status: s,
               type: work_package.type,
               role: member.roles.first)
      end
    end
  end
  let(:bcf_issue) { create(:bcf_issue, work_package:) }

  subject(:response) { last_response }

  describe "GET /api/bcf/2.1/projects/:project_id/topics" do
    let(:path) { "/api/bcf/2.1/projects/#{project.id}/topics" }
    let(:current_user) { view_only_user }

    before do
      login_as(current_user)
      bcf_issue
      other_status
      get path
    end

    it_behaves_like "bcf api successful response" do
      let(:expected_body) do
        work_package.reload
        [
          {
            assigned_to: assignee.mail,
            creation_author: work_package.author.mail,
            creation_date: work_package.created_at.iso8601(3),
            description: work_package.description,
            due_date: work_package.due_date.iso8601,
            guid: bcf_issue.uuid,
            index: bcf_issue.index,
            labels: bcf_issue.labels,
            priority: work_package.priority.name,
            modified_author: current_user.mail,
            modified_date: work_package.updated_at.iso8601(3),
            reference_links: [
              api_v3_paths.work_package(work_package.id)
            ],
            stage: bcf_issue.stage,
            title: work_package.subject,
            topic_status: work_package.status.name,
            topic_type: work_package.type.name,
            authorization: {
              topic_status: [],
              topic_actions: []
            }
          }
        ]
      end
    end

    context "lacking permission to see project" do
      let(:current_user) { non_member_user }

      it_behaves_like "bcf api not found response"
    end

    context "lacking permission to see linked issues" do
      let(:current_user) { only_member_user }

      it_behaves_like "bcf api not allowed response"
    end

    context "having edit permission" do
      let(:current_user) { edit_member_user }

      it_behaves_like "bcf api successful response" do
        let(:expected_body) do
          work_package.reload

          [
            {
              assigned_to: assignee.mail,
              creation_author: work_package.author.mail,
              creation_date: work_package.created_at.iso8601(3),
              description: work_package.description,
              due_date: work_package.due_date.iso8601,
              guid: bcf_issue.uuid,
              index: bcf_issue.index,
              labels: bcf_issue.labels,
              priority: work_package.priority.name,
              modified_author: current_user.mail,
              modified_date: work_package.updated_at.iso8601(3),
              reference_links: [
                api_v3_paths.work_package(work_package.id)
              ],
              stage: bcf_issue.stage,
              title: work_package.subject,
              topic_status: work_package.status.name,
              topic_type: work_package.type.name,
              authorization: {
                topic_status: [work_package.status.name, other_status.name],
                topic_actions: %w[update updateRelatedTopics updateFiles createViewpoint]
              }
            }
          ]
        end
      end
    end
  end

  describe "GET /api/bcf/2.1/projects/:project_id/topics/:uuid" do
    let(:path) { "/api/bcf/2.1/projects/#{project.id}/topics/#{bcf_issue.uuid}" }
    let(:current_user) { view_only_user }

    before do
      login_as(current_user)
      bcf_issue
      other_status
      get path
    end

    it_behaves_like "bcf api successful response" do
      let(:expected_body) do
        work_package.reload

        {
          assigned_to: assignee.mail,
          creation_author: work_package.author.mail,
          creation_date: work_package.created_at.iso8601(3),
          description: work_package.description,
          due_date: work_package.due_date.iso8601,
          guid: bcf_issue.uuid,
          index: bcf_issue.index,
          labels: bcf_issue.labels,
          priority: work_package.priority.name,
          modified_author: current_user.mail,
          modified_date: work_package.updated_at.iso8601(3),
          reference_links: [
            api_v3_paths.work_package(work_package.id)
          ],
          stage: bcf_issue.stage,
          title: work_package.subject,
          topic_status: work_package.status.name,
          topic_type: work_package.type.name,
          authorization: {
            topic_status: [],
            topic_actions: []
          }
        }
      end
    end

    context "lacking permission to see project" do
      let(:current_user) { non_member_user }

      it_behaves_like "bcf api not found response"
    end

    context "invalid uuid" do
      let(:path) { "/api/bcf/2.1/projects/#{project.id}/topics/0" }

      it_behaves_like "bcf api not found response"
    end

    context "lacking permission to see linked issues" do
      let(:current_user) { only_member_user }

      it_behaves_like "bcf api not allowed response"
    end

    context "having edit permission" do
      let(:current_user) { edit_member_user }

      it_behaves_like "bcf api successful response" do
        let(:expected_body) do
          work_package.reload

          {
            assigned_to: assignee.mail,
            creation_author: work_package.author.mail,
            creation_date: work_package.created_at.iso8601(3),
            description: work_package.description,
            due_date: work_package.due_date.iso8601,
            guid: bcf_issue.uuid,
            index: bcf_issue.index,
            labels: bcf_issue.labels,
            priority: work_package.priority.name,
            modified_author: current_user.mail,
            modified_date: work_package.updated_at.iso8601(3),
            reference_links: [
              api_v3_paths.work_package(work_package.id)
            ],
            stage: bcf_issue.stage,
            title: work_package.subject,
            topic_status: work_package.status.name,
            topic_type: work_package.type.name,
            authorization: {
              topic_status: [work_package.status.name, other_status.name],
              topic_actions: %w[update updateRelatedTopics updateFiles createViewpoint]
            }
          }
        end
      end
    end
  end

  describe "DELETE /api/bcf/2.1/projects/:project_id/topics/:uuid" do
    let(:path) { "/api/bcf/2.1/projects/#{project.id}/topics/#{bcf_issue.uuid}" }
    let(:current_user) { edit_and_delete_member_user }

    before do
      login_as(current_user)
      bcf_issue
      work_package
      delete path
    end

    it_behaves_like "bcf api successful response" do
      let(:expected_status) { 204 }
      let(:expected_body) { nil }
      let(:no_content) { true }
    end

    it "deletes the Bcf Issue as well as the belonging Work Package" do
      expect(WorkPackage.where(id: work_package.id)).to be_empty
      expect(Bim::Bcf::Issue.where(id: bcf_issue.id)).to be_empty
    end

    context "lacking permission to delete bcf" do
      let(:current_user) { edit_member_user }

      it_behaves_like "bcf api not allowed response"

      it "deletes neither the Work Package nor the Bcf Issue" do
        expect(WorkPackage.where(id: work_package.id)).to contain_exactly(work_package)
        expect(Bim::Bcf::Issue.where(id: bcf_issue.id)).to contain_exactly(bcf_issue)
      end
    end
  end

  shared_examples_for "topics api write invalid parameters errors" do
    context "without a title" do
      let(:params) do
        {}
      end

      it_behaves_like "bcf api unprocessable response" do
        let(:message) do
          "Title can't be blank."
        end
      end
    end

    context "with an inexistent status" do
      let(:params) do
        {
          title: "Some title",
          topic_status: "Some non existing status"
        }
      end

      it_behaves_like "bcf api unprocessable response" do
        let(:message) do
          "Status does not exist."
        end
      end
    end

    context "with an inexistent priority" do
      let(:params) do
        {
          title: "Some title",
          priority: "Some non existing priority"
        }
      end

      it_behaves_like "bcf api unprocessable response" do
        let(:message) do
          "Priority does not exist."
        end
      end
    end

    context "with an inexistent type" do
      let(:params) do
        {
          title: "Some title",
          topic_type: "Some non existing type"
        }
      end

      it_behaves_like "bcf api unprocessable response" do
        let(:message) do
          "Type does not exist."
        end
      end
    end

    context "with an inexistent assigned_to" do
      let(:params) do
        {
          title: "Some title",
          assigned_to: "Some non existing assignee"
        }
      end

      it_behaves_like "bcf api unprocessable response" do
        let(:message) do
          "Assignee does not exist."
        end
      end
    end

    context "with two inexistent related resources" do
      let(:params) do
        {
          title: "Some title",
          assigned_to: "Some non existing assignee",
          topic_type: "Some non existing type"
        }
      end

      it_behaves_like "bcf api unprocessable response" do
        let(:message) do
          "Multiple field constraints have been violated. Type does not exist. Assignee does not exist."
        end
      end
    end

    context "with a label" do
      let(:params) do
        {
          title: "Some title",
          labels: ["some label"]
        }
      end

      it_behaves_like "bcf api unprocessable response" do
        let(:message) do
          "Labels was attempted to be written but is not writable."
        end
      end
    end

    context "with a stage" do
      let(:params) do
        {
          title: "Some title",
          stage: "some stage"
        }
      end

      it_behaves_like "bcf api unprocessable response" do
        let(:message) do
          "Stage was attempted to be written but is not writable."
        end
      end
    end

    context "with reference links" do
      let(:params) do
        {
          title: "Some title",
          reference_links: [
            "/some/relative/links"
          ]
        }
      end

      it_behaves_like "bcf api unprocessable response" do
        let(:message) do
          "Reference links was attempted to be written but is not writable."
        end
      end
    end

    context "with bim_snippet" do
      let(:params) do
        {
          title: "Some title",
          bim_snippet: {
            snippet_type: "clash",
            is_external: true,
            reference: "https://example.com/bcf/1.0/ADFE23AA11BCFF444122BB",
            reference_schema: "https://example.com/bcf/1.0/clash.xsd"
          }
        }
      end

      it_behaves_like "bcf api unprocessable response" do
        let(:message) do
          "Bim snippet was attempted to be written but is not writable."
        end
      end
    end
  end

  describe "POST /api/bcf/2.1/projects/:project_id/topics" do
    let(:path) { "/api/bcf/2.1/projects/#{project.id}/topics" }
    let(:current_user) { edit_member_user }
    let(:type) do
      create(:type).tap do |t|
        project.types << t
      end
    end
    let(:status) do
      create(:status)
    end
    let!(:default_status) do
      create(:default_status)
    end
    let(:other_status) do
      create(:status).tap do |s|
        member = current_user.members.detect { |m| m.project_id == project.id }

        if member
          create(:workflow,
                 old_status: status,
                 new_status: s,
                 type:,
                 role: member.roles.first)
        end
      end
    end
    let!(:default_type) do
      create(:type, is_default: true)
    end
    let!(:standard_type) do
      create(:type_standard)
    end
    let!(:priority) do
      create(:priority)
    end
    let!(:default_priority) do
      create(:default_priority)
    end
    let(:description) { "some description" }
    let(:stage) { nil }
    let(:labels) { [] }
    let(:index) { 5 }
    let(:params) do
      {
        topic_type: type.name,
        topic_status: status.name,
        priority: priority.name,
        title: "BCF topic 101",
        labels:,
        stage:,
        index:,
        due_date: Date.today.iso8601,
        assigned_to: view_only_user.mail,
        description:
      }
    end

    before do
      login_as(current_user)
      other_status
      post path, params.to_json
    end

    it_behaves_like "bcf api successful response" do
      let(:expected_status) { 201 }
      let(:expected_body) do
        issue = Bim::Bcf::Issue.last.reload
        work_package = WorkPackage.last.reload

        {
          guid: issue&.uuid,
          topic_type: type.name,
          topic_status: status.name,
          priority: priority.name,
          title: "BCF topic 101",
          labels:,
          index:,
          reference_links: [
            api_v3_paths.work_package(work_package&.id)
          ],
          assigned_to: view_only_user.mail,
          due_date: Date.today.iso8601,
          stage:,
          creation_author: edit_member_user.mail,
          creation_date: work_package&.created_at&.iso8601(3),
          modified_author: edit_member_user.mail,
          modified_date: work_package&.updated_at&.iso8601(3),
          description:,
          authorization: {
            topic_status: [other_status.name, status.name],
            topic_actions: %w[update updateRelatedTopics updateFiles createViewpoint]
          }
        }
      end
    end

    def expected_body_for_bcf_issue(
      issue,
      title:,
      creation_author_mail: nil,
      modified_author_mail: nil,
      assigned_to: nil,
      due_date: nil,
      description: nil,
      base: nil
    )
      work_package = (base || issue.work_package).reload

      {
        guid: issue&.uuid,
        topic_type: (base && base.type.name) || type.name,
        topic_status: (base && base.status.name) || default_status.name,
        priority: (base && base.priority.name) || default_priority.name,
        title:,
        labels: [],
        index: nil,
        reference_links: [
          api_v3_paths.work_package(work_package&.id)
        ],
        assigned_to: assigned_to || base&.assigned_to&.mail,
        due_date: due_date || base&.due_date,
        stage: nil,
        creation_author: creation_author_mail,
        creation_date: work_package&.created_at,
        modified_author: modified_author_mail,
        modified_date: work_package&.updated_at,
        description: description || base&.description,
        authorization: {
          topic_status: [(base && base.status.name) || default_status.name],
          topic_actions: %w[update updateRelatedTopics updateFiles createViewpoint]
        }
      }
    end

    context "with minimal parameters" do
      let(:params) do
        {
          title: "BCF topic 101"
        }
      end

      it_behaves_like "bcf api successful response" do
        let(:expected_status) { 201 }
        let(:expected_body) do
          expected_body_for_bcf_issue(
            Bim::Bcf::Issue.last.reload,
            title: params[:title],
            creation_author_mail: edit_member_user.mail,
            modified_author_mail: edit_member_user.mail
          )
        end
      end
    end

    context "with an existing work package" do
      let!(:existing_work_package) do
        create(:work_package, author: assignee, assigned_to: assignee, project:)
      end

      let(:params) do
        {
          title: "BCF topic ##{existing_work_package.id}",
          reference_links: [
            api_v3_paths.work_package(existing_work_package.id)
          ]
        }
      end

      it_behaves_like "bcf api successful response" do
        let(:expected_status) { 201 }
        let(:expected_body) do
          expected_body_for_bcf_issue(
            Bim::Bcf::Issue.last.reload,
            title: params[:title],
            creation_author_mail: existing_work_package.author.mail,
            modified_author_mail: edit_member_user.mail,
            base: existing_work_package
          )
        end
      end

      context "with a non-existing work package" do
        let(:params) do
          {
            title: "A new BCF topic",
            reference_links: [
              api_v3_paths.work_package(WorkPackage.last&.id.to_i + 42)
            ]
          }
        end

        it_behaves_like "bcf api unprocessable response" do
          let(:message) { "Work package does not exist." }
        end
      end

      context "with a work package where the user is not a bcf manager" do
        let(:current_user) { view_only_user }

        let(:params) do
          {
            title: "Another new BCF topic",
            reference_links: [
              api_v3_paths.work_package(work_package.id)
            ]
          }
        end

        it "responds with a not authorized error" do
          expect(response).to have_http_status :forbidden
          expect(response.body).to include "You are not authorized to access this resource."
        end
      end

      context "with a work package in another project" do
        let!(:foreign_work_package) { create(:work_package) }

        let(:params) do
          {
            title: "Yet another new BCF topic",
            reference_links: [
              api_v3_paths.work_package(foreign_work_package.id)
            ]
          }
        end

        it "responds with a not authorized error" do
          expect(response).to have_http_status :not_found
          expect(response.body).to include "The requested resource could not be found."
        end
      end

      context "with a work package that already belongs to a BCF issue" do
        let(:params) do
          {
            title: "A BCF topic that shouldn't be",
            reference_links: [
              api_v3_paths.work_package(bcf_issue.work_package.id)
            ]
          }
        end

        it_behaves_like "bcf api unprocessable response" do
          let(:message) { "Work package has already been taken." }
        end
      end
    end

    it_behaves_like "topics api write invalid parameters errors"

    context "if not allowed to add topics" do
      let(:current_user) { view_only_user }

      it_behaves_like "bcf api not allowed response"
    end
  end

  describe "PUT /api/bcf/2.1/projects/:project_id/topics/:guid" do
    let(:path) { "/api/bcf/2.1/projects/#{project.id}/topics/#{bcf_issue.uuid}" }
    let(:current_user) { edit_member_user }
    let!(:type) do
      create(:type).tap do |t|
        project.types << t
      end
    end
    let(:status) do
      create(:status)
    end
    let(:other_status) do
      create(:status).tap do |s|
        member = current_user.members.detect { |m| m.project_id == project.id }

        if member
          create(:workflow,
                 old_status: status,
                 new_status: s,
                 type:,
                 role: member.roles.first)
        end
      end
    end
    let!(:default_status) do
      create(:default_status)
    end
    let!(:default_type) do
      create(:type, is_default: true).tap do |t|
        project.types << t
      end
    end
    let!(:priority) do
      create(:priority)
    end
    let!(:default_priority) do
      create(:default_priority)
    end
    let(:description) { "some description" }
    let(:index) { 5 }
    let(:params) do
      {
        topic_type: type.name,
        topic_status: status.name,
        priority: priority.name,
        title: "BCF topic 101",
        index:,
        due_date: Date.today.iso8601,
        assigned_to: view_only_user.mail,
        description:
      }
    end

    before do
      login_as(current_user)
      other_status
      put path, params.to_json
    end

    it_behaves_like "bcf api successful response" do
      let(:expected_body) do
        work_package.reload

        {
          guid: bcf_issue&.uuid,
          topic_type: type.name,
          topic_status: status.name,
          priority: priority.name,
          title: "BCF topic 101",
          labels: [],
          index:,
          reference_links: [
            api_v3_paths.work_package(work_package&.id)
          ],
          assigned_to: view_only_user.mail,
          due_date: Date.today.iso8601,
          stage: nil,
          creation_author: work_package.author.mail,
          creation_date: work_package&.created_at&.iso8601(3),
          modified_author: edit_member_user.mail,
          modified_date: work_package&.updated_at&.iso8601(3),
          description:,
          authorization: {
            topic_status: [other_status.name, status.name],
            topic_actions: %w[update updateRelatedTopics updateFiles createViewpoint]
          }
        }
      end
    end

    context "with only the minimally required property (title)" do
      let(:new_title) { "New title" }
      let(:params) do
        {
          title: new_title
        }
      end

      it_behaves_like "bcf api successful response" do
        let(:expected_body) do
          reloaded_work_package = WorkPackage.find(work_package.id)

          {
            guid: bcf_issue&.uuid,
            topic_type: default_type.name,
            topic_status: default_status.name,
            priority: default_priority.name,
            title: new_title,
            labels: [],
            index: nil,
            reference_links: [
              api_v3_paths.work_package(work_package&.id)
            ],
            assigned_to: nil,
            due_date: nil,
            stage: nil,
            creation_author: work_package.author.mail,
            creation_date: work_package&.created_at&.iso8601(3),
            modified_author: edit_member_user.mail,
            modified_date: reloaded_work_package&.updated_at&.iso8601(3),
            description: nil,
            authorization: {
              topic_status: [default_status.name],
              topic_actions: %w[update updateRelatedTopics updateFiles createViewpoint]
            }
          }
        end
      end
    end

    it_behaves_like "topics api write invalid parameters errors"

    context "if not allowed to alter topics" do
      let(:current_user) { view_only_user }

      it_behaves_like "bcf api not allowed response"
    end
  end
end
