#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2019 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'
require 'rack/test'

require_relative './shared_responses'

describe 'BCF 2.1 topics resource', type: :request, content_type: :json, with_mail: false do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  let(:view_only_user) do
    FactoryBot.create(:user,
                      member_in_project: project,
                      member_with_permissions: %i[view_linked_issues view_work_packages])
  end
  let(:only_member_user) do
    FactoryBot.create(:user,
                      member_in_project: project,
                      member_with_permissions: [])
  end
  let(:edit_member_user) do
    FactoryBot.create(:user,
                      member_in_project: project,
                      member_with_permissions: %i[manage_bcf add_work_packages view_linked_issues delete_work_packages])
  end
  let(:edit_work_package_member_user) do
    FactoryBot.create(:user,
                      member_in_project: project,
                      member_with_permissions: %i[add_work_packages delete_work_packages])
  end
  let(:non_member_user) do
    FactoryBot.create(:user)
  end

  let(:project) do
    FactoryBot.create(:project,
                      enabled_module_names: %i[bcf work_package_tracking])
  end
  let(:assignee) { FactoryBot.create(:user) }
  let(:work_package) do
    FactoryBot.create(:work_package,
                      assigned_to: assignee,
                      project: project)
  end
  let(:bcf_issue) { FactoryBot.create(:bcf_issue, work_package: work_package) }

  subject(:response) { last_response }

  describe 'GET /api/bcf/2.1/projects/:project_id/topics' do
    let(:path) { "/api/bcf/2.1/projects/#{project.id}/topics" }
    let(:current_user) { view_only_user }

    before do
      login_as(current_user)
      bcf_issue
      get path
    end

    it_behaves_like 'bcf api successful response' do
      let(:expected_body) do
        [
          {
            "assigned_to": assignee.mail,
            "creation_author": work_package.author.mail,
            "creation_date": work_package.created_at.iso8601,
            "description": work_package.description,
            "due_date": nil,
            "guid": bcf_issue.uuid,
            "index": bcf_issue.index,
            "labels": bcf_issue.labels,
            "priority": work_package.priority.name,
            "modified_author": current_user.mail,
            "modified_date": work_package.updated_at.iso8601,
            "reference_links": [
              api_v3_paths.work_package(work_package.id)
            ],
            "stage": bcf_issue.stage,
            "title": work_package.subject,
            "topic_status": work_package.status.name,
            "topic_type": work_package.type.name
          }
        ]
      end
    end

    context 'lacking permission to see project' do
      let(:current_user) { non_member_user }

      it_behaves_like 'bcf api not found response'
    end

    context 'lacking permission to see linked issues' do
      let(:current_user) { only_member_user }

      it_behaves_like 'bcf api not allowed response'
    end
  end

  describe 'GET /api/bcf/2.1/projects/:project_id/topics/:uuid' do
    let(:path) { "/api/bcf/2.1/projects/#{project.id}/topics/#{bcf_issue.uuid}" }
    let(:current_user) { view_only_user }

    before do
      login_as(current_user)
      bcf_issue
      get path
    end

    it_behaves_like 'bcf api successful response' do
      let(:expected_body) do
        {
          "assigned_to": assignee.mail,
          "creation_author": work_package.author.mail,
          "creation_date": work_package.created_at.iso8601,
          "description": work_package.description,
          "due_date": nil,
          "guid": bcf_issue.uuid,
          "index": bcf_issue.index,
          "labels": bcf_issue.labels,
          "priority": work_package.priority.name,
          "modified_author": current_user.mail,
          "modified_date": work_package.updated_at.iso8601,
          "reference_links": [
            api_v3_paths.work_package(work_package.id)
          ],
          "stage": bcf_issue.stage,
          "title": work_package.subject,
          "topic_status": work_package.status.name,
          "topic_type": work_package.type.name
        }
      end
    end

    context 'lacking permission to see project' do
      let(:current_user) { non_member_user }

      it_behaves_like 'bcf api not found response'
    end

    context 'invalid uuid' do
      let(:path) { "/api/bcf/2.1/projects/#{project.id}/topics/0" }

      it_behaves_like 'bcf api not found response'
    end

    context 'lacking permission to see linked issues' do
      let(:current_user) { only_member_user }

      it_behaves_like 'bcf api not allowed response'
    end
  end

  describe 'DELETE /api/bcf/2.1/projects/:project_id/topics/:uuid' do
    let(:path) { "/api/bcf/2.1/projects/#{project.id}/topics/#{bcf_issue.uuid}" }
    let(:current_user) { edit_member_user }

    before do
      login_as(current_user)
      bcf_issue
      work_package
      delete path
    end

    it_behaves_like 'bcf api successful response' do
      let(:expected_status) { 204 }
      let(:expected_body) { nil }
      let(:no_content) { true }
    end

    it 'deletes the Bcf Issue as well as the belonging Work Package' do
      expect(WorkPackage.where(id: work_package.id)).to match_array []
      expect(Bcf::Issue.where(id: bcf_issue.id)).to match_array []
    end

    context 'lacking permission to manage bcf' do
      let(:current_user) { edit_work_package_member_user }

      it_behaves_like 'bcf api not allowed response'

      it 'deletes neither the Work Package nor the Bcf Issue' do
        expect(WorkPackage.where(id: work_package.id)).to match_array [work_package]
        expect(Bcf::Issue.where(id: bcf_issue.id)).to match_array [bcf_issue]
      end
    end
  end

  describe 'POST /api/bcf/2.1/projects/:project_id/topics' do
    let(:path) { "/api/bcf/2.1/projects/#{project.id}/topics" }
    let(:current_user) { edit_member_user }
    let(:type) do
      FactoryBot.create(:type).tap do |t|
        project.types << t
      end
    end
    let(:status) do
      FactoryBot.create(:status)
    end
    let!(:default_status) do
      FactoryBot.create(:default_status)
    end
    let!(:default_type) do
      FactoryBot.create(:type, is_default: true)
    end
    let!(:standard_type) do
      FactoryBot.create(:type_standard)
    end
    let!(:priority) do
      FactoryBot.create(:priority)
    end
    let!(:default_priority) do
      FactoryBot.create(:default_priority)
    end
    let(:description) { 'some description' }
    let(:stage) { nil }
    let(:labels) { [] }
    let(:index) { 5 }
    let(:params) do
      {
        topic_type: type.name,
        topic_status: status.name,
        priority: priority.name,
        title: 'BCF topic 101',
        labels: labels,
        stage: stage,
        index: index,
        due_date: Date.today.iso8601,
        assigned_to: view_only_user.mail,
        description: description
      }
    end

    before do
      login_as(current_user)
      post path, params.to_json
    end

    it_behaves_like 'bcf api successful response' do
      let(:expected_status) { 201 }
      let(:expected_body) do
        issue = Bcf::Issue.last
        work_package = WorkPackage.last

        {
          guid: issue&.uuid,
          topic_type: type.name,
          topic_status: status.name,
          priority: priority.name,
          title: 'BCF topic 101',
          labels: labels,
          index: index,
          reference_links: [
            api_v3_paths.work_package(work_package&.id)
          ],
          assigned_to: view_only_user.mail,
          due_date: Date.today.iso8601,
          stage: stage,
          creation_author: edit_member_user.mail,
          creation_date: work_package&.created_at&.iso8601,
          modified_author: edit_member_user.mail,
          modified_date: work_package&.updated_at&.iso8601,
          description: description
        }
      end
    end

    context 'with minimal parameters' do
      let(:params) do
        {
          title: 'BCF topic 101'
        }
      end

      it_behaves_like 'bcf api successful response' do
        let(:expected_status) { 201 }
        let(:expected_body) do
          issue = Bcf::Issue.last
          work_package = WorkPackage.last

          {
            guid: issue&.uuid,
            topic_type: standard_type.name,
            topic_status: default_status.name,
            priority: default_priority.name,
            title: 'BCF topic 101',
            labels: [],
            index: nil,
            reference_links: [
              api_v3_paths.work_package(work_package&.id)
            ],
            assigned_to: nil,
            due_date: nil,
            stage: nil,
            creation_author: edit_member_user.mail,
            creation_date: work_package&.created_at&.iso8601,
            modified_author: edit_member_user.mail,
            modified_date: work_package&.updated_at&.iso8601,
            description: nil
          }
        end
      end
    end

    context 'without a title' do
      let(:params) do
        {
        }
      end

      it_behaves_like 'bcf api unprocessable response' do
        let(:message) do
          "Title can't be blank."
        end
      end
    end

    context 'with an inexistent status' do
      let(:params) do
        {
          title: 'Some title',
          topic_status: 'Some non existing status'
        }
      end

      it_behaves_like 'bcf api unprocessable response' do
        let(:message) do
          "Status does not exist."
        end
      end
    end

    context 'with an inexistent priority' do
      let(:params) do
        {
          title: 'Some title',
          priority: 'Some non existing priority'
        }
      end

      it_behaves_like 'bcf api unprocessable response' do
        let(:message) do
          "Priority does not exist."
        end
      end
    end

    context 'with an inexistent type' do
      let(:params) do
        {
          title: 'Some title',
          topic_type: 'Some non existing type'
        }
      end

      it_behaves_like 'bcf api unprocessable response' do
        let(:message) do
          "Type does not exist."
        end
      end
    end

    context 'with an inexistent assigned_to' do
      let(:params) do
        {
          title: 'Some title',
          assigned_to: 'Some non existing assignee'
        }
      end

      it_behaves_like 'bcf api unprocessable response' do
        let(:message) do
          "Assignee does not exist."
        end
      end
    end

    context 'with two inexistent related resources' do
      let(:params) do
        {
          title: 'Some title',
          assigned_to: 'Some non existing assignee',
          topic_type: 'Some non existing type'
        }
      end

      it_behaves_like 'bcf api unprocessable response' do
        let(:message) do
          "Multiple field constraints have been violated. Type does not exist. Assignee does not exist."
        end
      end
    end

    context 'with a label' do
      let(:params) do
        {
          title: 'Some title',
          labels: ['some label']
        }
      end

      it_behaves_like 'bcf api unprocessable response' do
        let(:message) do
          "Labels was attempted to be written but is not writable."
        end
      end
    end

    context 'with a stage' do
      let(:params) do
        {
          title: 'Some title',
          stage: 'some stage'
        }
      end

      it_behaves_like 'bcf api unprocessable response' do
        let(:message) do
          "Stage was attempted to be written but is not writable."
        end
      end
    end
  end
end
