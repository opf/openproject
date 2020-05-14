#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
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

describe 'API v3 Work package resource',
         type: :request,
         content_type: :json do
  include Rack::Test::Methods
  include Capybara::RSpecMatchers
  include API::V3::Utilities::PathHelper

  let(:closed_status) { FactoryBot.create(:closed_status) }

  let(:work_package) do
    FactoryBot.create(:work_package,
                      project_id: project.id,
                      description: 'lorem ipsum')
  end
  let(:project) do
    FactoryBot.create(:project, identifier: 'test_project', public: false)
  end
  let(:role) { FactoryBot.create(:role, permissions: permissions) }
  let(:permissions) { %i[view_work_packages edit_work_packages assign_versions] }
  let(:current_user) do
    user = FactoryBot.create(:user, member_in_project: project, member_through_role: role)

    FactoryBot.create(:user_preference, user: user, others: {no_self_notified: false})

    user
  end
  let(:watcher) do
    FactoryBot
      .create(:user, member_in_project: project, member_through_role: role)
      .tap do |user|
        work_package.add_watcher(user)
      end
  end
  let(:unauthorize_user) { FactoryBot.create(:user) }
  let(:type) { FactoryBot.create(:type) }

  before do
    login_as(current_user)
  end

  describe 'GET /api/v3/work_packages' do
    subject { last_response }

    let(:path) { api_v3_paths.work_packages }
    let(:other_work_package) { FactoryBot.create(:work_package) }
    let(:work_packages) { [work_package, other_work_package] }

    before(:each) do
      work_packages
      get path
    end

    it 'succeeds' do
      expect(subject.status).to eql 200
    end

    it 'returns visible work packages' do
      expect(subject.body).to be_json_eql(1.to_json).at_path('total')
    end

    it 'embedds the work package schemas' do
      expect(subject.body)
        .to be_json_eql(api_v3_paths.work_package_schema(project.id, work_package.type.id).to_json)
        .at_path('_embedded/schemas/_embedded/elements/0/_links/self/href')
    end

    context 'user not seeing any work packages' do
      include_context 'with non-member permissions from non_member_permissions'
      let(:current_user) { FactoryBot.create(:user) }
      let(:non_member_permissions) { [:view_work_packages] }

      it 'succeeds' do
        expect(subject.status).to eql 200
      end

      it 'returns no work packages' do
        expect(subject.body).to be_json_eql(0.to_json).at_path('total')
      end

      context 'because he is not allowed to see work packages in general' do
        let(:non_member_permissions) { [] }

        it_behaves_like 'unauthorized access'
      end
    end

    describe 'encoded query props' do
      let(:props) do
        eprops = {
          filters: [{ id: { operator: '=', values: [work_package.id.to_s, other_visible_work_package.id.to_s] } }].to_json,
          sortBy: [%w(id asc)].to_json,
          pageSize: 1
        }.to_json

        {
          eprops: Base64.encode64(Zlib::Deflate.deflate(eprops))
        }.to_query
      end
      let(:path) { "#{api_v3_paths.work_packages}?#{props}" }
      let(:other_visible_work_package) do
        FactoryBot.create(:work_package,
                          project: project)
      end
      let(:another_visible_work_package) do
        FactoryBot.create(:work_package,
                          project: project)
      end

      let(:work_packages) { [work_package, other_work_package, other_visible_work_package, another_visible_work_package] }

      it 'succeeds' do
        expect(subject.status)
          .to eql 200
      end

      it 'returns visible and filtered work packages' do
        expect(subject.body)
          .to be_json_eql(2.to_json)
          .at_path('total')

        # because of the page size
        expect(subject.body)
          .to be_json_eql(1.to_json)
          .at_path('count')

        expect(subject.body)
          .to be_json_eql(work_package.id.to_json)
          .at_path('_embedded/elements/0/id')
      end

      context 'non zlibbed' do
        let(:props) do
          eprops = {
            filters: [{ id: { operator: '=', values: [work_package.id.to_s, other_visible_work_package.id.to_s] } }].to_json,
            sortBy: [%w(id asc)].to_json,
            pageSize: 1
          }.to_json

          {
            eprops: Base64.encode64(eprops)
          }.to_query
        end

        it_behaves_like 'param validation error'
      end

      context 'non json encoded' do
        let(:props) do
          eprops = "some non json string"

          {
            eprops: Base64.encode64(Zlib::Deflate.deflate(eprops))
          }.to_query
        end

        it_behaves_like 'param validation error'
      end

      context 'non base64 encoded' do
        let(:props) do
          eprops = {
            filters: [{ id: { operator: '=', values: [work_package.id.to_s, other_visible_work_package.id.to_s] } }].to_json,
            sortBy: [%w(id asc)].to_json,
            pageSize: 1
          }.to_json

          {
            eprops: Zlib::Deflate.deflate(eprops)
          }.to_query
        end

        it_behaves_like 'param validation error'
      end

      context 'non hash' do
        let(:props) do
          eprops = [{
            filters: [{ id: { operator: '=', values: [work_package.id.to_s, other_visible_work_package.id.to_s] } }].to_json,
            sortBy: [%w(id asc)].to_json,
            pageSize: 1
          }].to_json

          {
            eprops: Base64.encode64(Zlib::Deflate.deflate(eprops))
          }.to_query
        end

        it_behaves_like 'param validation error'
      end
    end
  end

  describe 'GET /api/v3/work_packages/:id' do
    let(:get_path) { api_v3_paths.work_package work_package.id }

    context 'when acting as a user with permission to view work package' do
      before(:each) do
        allow(User).to receive(:current).and_return current_user
        get get_path
      end

      it 'should respond with 200' do
        expect(last_response.status).to eq(200)
      end

      describe 'response body' do
        subject(:parsed_response) { JSON.parse(last_response.body) }
        let!(:other_wp) do
          FactoryBot.create(:work_package, project_id: project.id,
                            status: closed_status)
        end
        let(:work_package) do
          FactoryBot.create(:work_package, project_id: project.id,
                            description: description)
        end
        let(:description) do
          <<~DESCRIPTION
            <macro class="toc"><macro>

            # OpenProject Masterplan for 2015

            ## three point plan

            1) One ###{other_wp.id}
            2) Two
            3) Three

            ### random thoughts

            ### things we like

            * Pointed
            * Relaxed
            * Debonaire
          DESCRIPTION
        end

        it 'should respond with work package in HAL+JSON format' do
          expect(parsed_response['id']).to eq(work_package.id)
        end

        describe "['description']" do
          subject { super()['description'] }
          it { is_expected.to have_selector('h1') }
        end

        describe "['description']" do
          subject { super()['description'] }
          it { is_expected.to have_selector('h2') }
        end

        it 'should resolve links' do
          expect(parsed_response['description']['html'])
            .to have_selector("a[href='/work_packages/#{other_wp.id}']")
        end

        it 'should resolve simple macros' do
          expect(parsed_response['description']).to have_text('Table of contents')
        end
      end

      context 'requesting nonexistent work package' do
        let(:get_path) { api_v3_paths.work_package 909090 }

        it_behaves_like 'not found'
      end
    end

    context 'when acting as an user without permission to view work package' do
      before(:each) do
        allow(User).to receive(:current).and_return unauthorize_user
        get get_path
      end

      it_behaves_like 'not found'
    end

    context 'when acting as an anonymous user' do
      before(:each) do
        allow(User).to receive(:current).and_return User.anonymous
        get get_path
      end

      it_behaves_like 'not found'
    end
  end

  describe 'PATCH /api/v3/work_packages/:id' do
    let(:patch_path) { api_v3_paths.work_package work_package.id }
    let(:valid_params) do
      {
        _type: 'WorkPackage',
        lockVersion: work_package.lock_version
      }
    end

    subject(:response) { last_response }

    shared_context 'patch request' do
      before(:each) do
        allow(User).to receive(:current).and_return current_user
        patch patch_path, params.to_json, 'CONTENT_TYPE' => 'application/json'
      end
    end

    context 'user without needed permissions' do
      context 'no permission to see the work package' do
        let(:work_package) { FactoryBot.create(:work_package) }
        let(:current_user) { FactoryBot.create :user }
        let(:params) { valid_params }

        include_context 'patch request'

        it_behaves_like 'not found'
      end

      context 'no permission to edit the work package' do
        let(:role) { FactoryBot.create(:role, permissions: [:view_work_packages]) }
        let(:current_user) do
          FactoryBot.create(:user,
                            member_in_project: work_package.project,
                            member_through_role: role)
        end
        let(:params) { valid_params }

        include_context 'patch request'

        it_behaves_like 'unauthorized access'
      end
    end

    context 'user with needed permissions' do
      shared_examples_for 'lock version updated' do
        it {
          expect(subject.body)
            .to be_json_eql(work_package.reload.lock_version)
            .at_path('lockVersion')
        }
      end

      describe 'notification' do
        let(:update_params) { valid_params.merge(subject: 'Updated subject') }

        before(:each) do
          allow(User).to receive(:current).and_return current_user
          work_package
        end

        include_context 'patch request'

        context 'not set' do
          let(:params) { update_params }

          it { expect(EnqueueWorkPackageNotificationJob).to have_been_enqueued.at_least(1) }
        end

        context 'disabled' do
          let(:patch_path) { "#{api_v3_paths.work_package work_package.id}?notify=false" }
          let(:params) { update_params }

          it do
            expect(EnqueueWorkPackageNotificationJob)
              .to have_been_enqueued
              .at_least(1)
          end
        end

        context 'enabled' do
          let(:patch_path) { "#{api_v3_paths.work_package work_package.id}?notify=Something" }
          let(:params) { update_params }

          it do
            expect(EnqueueWorkPackageNotificationJob)
              .to have_been_enqueued
              .at_least(1)
          end
        end
      end

      context 'subject' do
        let(:params) { valid_params.merge(subject: 'Updated subject') }

        include_context 'patch request'

        it { expect(response.status).to eq(200) }

        it 'should respond with updated work package subject' do
          expect(subject.body).to be_json_eql('Updated subject'.to_json).at_path('subject')
        end

        it_behaves_like 'lock version updated'

        context 'for a user having assign_versions but lacking edit_work_packages permission' do
          let(:permissions) { %i[view_work_packages assign_versions] }

          include_context 'patch request'

          it { expect(response.status).to eq(422) }

          it 'has a readonly error' do
            expect(response.body)
              .to be_json_eql('urn:openproject-org:api:v3:errors:PropertyIsReadOnly'.to_json)
              .at_path('errorIdentifier')
          end
        end
      end

      context 'description' do
        shared_examples_for 'description updated' do
          it_behaves_like 'API V3 formattable', 'description' do
            let(:format) { 'markdown' }

            subject { response.body }
          end

          it_behaves_like 'lock version updated'
        end

        context 'w/o value (empty)' do
          let(:raw) { nil }
          let(:html) { '' }
          let(:params) { valid_params.merge(description: {raw: nil}) }

          include_context 'patch request'

          it { expect(response.status).to eq(200) }

          it_behaves_like 'description updated'
        end

        context 'with value' do
          let(:raw) { '**Some text** *describing* **something**...' }
          let(:html) do
            '<p><strong>Some text</strong> <em>describing</em> <strong>something</strong>...</p>'
          end
          let(:params) { valid_params.merge(description: {raw: raw}) }

          include_context 'patch request'

          it { expect(response.status).to eq(200) }

          it_behaves_like 'description updated'
        end
      end

      context 'schedule manually' do
        let(:schedule_manually) { true }
        let(:params) { valid_params.merge(scheduleManually: schedule_manually) }

        include_context 'patch request'

        it { expect(response.status).to eq(200) }

        it 'should update the scheduling mode' do
          expect(subject.body).to be_json_eql(schedule_manually.to_json).at_path('scheduleManually')
        end
      end

      context 'start date' do
        let(:dateString) { Date.today.to_date.iso8601 }
        let(:params) { valid_params.merge(startDate: dateString) }

        include_context 'patch request'

        it { expect(response.status).to eq(200) }

        it 'should respond with updated start date' do
          expect(subject.body).to be_json_eql(dateString.to_json).at_path('startDate')
        end

        it_behaves_like 'lock version updated'
      end

      context 'finish date' do
        let(:dateString) { Date.today.to_date.iso8601 }
        let(:params) { valid_params.merge(dueDate: dateString) }

        include_context 'patch request'

        it { expect(response.status).to eq(200) }

        it 'should respond with updated finish date' do
          expect(subject.body).to be_json_eql(dateString.to_json).at_path('dueDate')
        end

        it_behaves_like 'lock version updated'
      end

      context 'status' do
        let(:target_status) { FactoryBot.create(:status) }
        let(:status_link) { api_v3_paths.status target_status.id }
        let(:status_parameter) { {_links: {status: {href: status_link}}} }
        let(:params) { valid_params.merge(status_parameter) }

        before { allow(User).to receive(:current).and_return current_user }

        context 'valid status' do
          let!(:workflow) do
            FactoryBot.create(:workflow,
                              type_id: work_package.type.id,
                              old_status: work_package.status,
                              new_status: target_status,
                              role: current_user.memberships[0].roles[0])
          end

          include_context 'patch request'

          it { expect(response.status).to eq(200) }

          it 'should respond with updated work package status' do
            expect(subject.body).to be_json_eql(target_status.name.to_json)
                                      .at_path('_embedded/status/name')
          end

          it_behaves_like 'lock version updated'
        end

        context 'invalid status' do
          include_context 'patch request'

          it_behaves_like 'constraint violation' do
            let(:message) do
              'Status ' + I18n.t('activerecord.errors.models.' \
                          'work_package.attributes.status_id.status_transition_invalid')
            end
          end
        end

        context 'wrong resource' do
          let(:status_link) { api_v3_paths.user current_user.id }

          include_context 'patch request'

          it_behaves_like 'invalid resource link' do
            let(:message) do
              I18n.t('api_v3.errors.invalid_resource',
                     property: 'status',
                     expected: '/api/v3/statuses/:id',
                     actual: status_link)
            end
          end
        end
      end

      context 'type' do
        let(:target_type) { FactoryBot.create(:type) }
        let(:type_link) { api_v3_paths.type target_type.id }
        let(:type_parameter) { {_links: {type: {href: type_link}}} }
        let(:params) { valid_params.merge(type_parameter) }

        before { allow(User).to receive(:current).and_return current_user }

        context 'valid type' do
          before do
            project.types << target_type
          end

          include_context 'patch request'

          it { expect(response.status).to eq(200) }

          it 'should respond with updated work package type' do
            expect(subject.body).to be_json_eql(target_type.name.to_json)
                                      .at_path('_embedded/type/name')
          end

          it_behaves_like 'lock version updated'
        end

        context 'valid type changing custom fields' do
          let(:custom_field) { FactoryBot.create(:work_package_custom_field) }
          let(:custom_field_parameter) { {:"customField#{custom_field.id}" => true} }
          let(:params) { valid_params.merge(type_parameter).merge(custom_field_parameter) }

          before do
            project.types << target_type
            project.work_package_custom_fields << custom_field
            target_type.custom_fields << custom_field
          end

          include_context 'patch request'

          it 'responds with the new custom field having the desired value' do
            expect(subject.body)
              .to be_json_eql(true.to_json)
                    .at_path("customField#{custom_field.id}")
          end
        end

        context 'invalid type' do
          include_context 'patch request'

          it_behaves_like 'constraint violation' do
            let(:message) { "Type #{I18n.t('activerecord.errors.messages.inclusion')}" }
          end
        end

        context 'wrong resource' do
          let(:type_link) { api_v3_paths.user current_user.id }

          include_context 'patch request'

          it_behaves_like 'invalid resource link' do
            let(:message) do
              I18n.t('api_v3.errors.invalid_resource',
                     property: 'type',
                     expected: '/api/v3/types/:id',
                     actual: type_link)
            end
          end
        end
      end

      context 'project' do
        let(:target_project) do
          FactoryBot.create(:project, public: false)
        end
        let(:project_link) { api_v3_paths.project target_project.id }
        let(:project_parameter) { {_links: {project: {href: project_link}}} }
        let(:params) { valid_params.merge(project_parameter) }

        before do
          FactoryBot.create :member,
                            user: current_user,
                            project: target_project,
                            roles: [FactoryBot.create(:role, permissions: [:move_work_packages])]

          allow(User).to receive(:current).and_return current_user
        end

        context 'is changed' do
          include_context 'patch request'

          it 'is successful' do
            expect(response.status).to eq(200)
          end

          it_behaves_like 'lock version updated'

          it 'responds with the project changed' do
            href = {
              href: project_link,
              title: target_project.name
            }
            expect(response.body).to be_json_eql(href.to_json).at_path('_links/project')
          end
        end

        context 'with a custom field defined on the target project' do
          let(:custom_field) { FactoryBot.create(:work_package_custom_field) }
          let(:custom_field_parameter) { {:"customField#{custom_field.id}" => true} }
          let(:params) { valid_params.merge(project_parameter).merge(custom_field_parameter) }

          before do
            target_project.work_package_custom_fields << custom_field
            work_package.type.custom_fields << custom_field
          end

          include_context 'patch request'

          it 'responds with the new custom field having the desired value' do
            expect(subject.body)
              .to be_json_eql(true.to_json)
              .at_path("customField#{custom_field.id}")
          end
        end
      end

      context 'assignee and responsible' do
        let(:user) { FactoryBot.create(:user, member_in_project: project) }
        let(:params) { valid_params.merge(user_parameter) }
        let(:work_package) do
          FactoryBot.create(:work_package,
                            project: project,
                            assigned_to: current_user,
                            responsible: current_user)
        end

        before { allow(User).to receive(:current).and_return current_user }

        shared_context 'setup group membership' do |group_assignment|
          let(:group) { FactoryBot.create(:group) }
          let(:group_role) { FactoryBot.create(:role) }
          let(:group_member) do
            FactoryBot.create(:member,
                              principal: group,
                              project: project,
                              roles: [group_role])
          end

          before do
            allow(Setting).to receive(:work_package_group_assignment?).and_return(group_assignment)

            group_member
          end
        end

        shared_examples_for 'handling people' do |property|
          let(:user_parameter) { {_links: {property => {href: user_href}}} }
          let(:href_path) { "_links/#{property}/href" }

          describe 'nil' do
            let(:user_href) { nil }

            include_context 'patch request'

            it { expect(response.status).to eq(200) }

            it { expect(response.body).to be_json_eql(nil.to_json).at_path(href_path) }

            it_behaves_like 'lock version updated'
          end

          describe 'valid' do
            shared_examples_for 'valid user assignment' do
              let(:title) { "#{assigned_user.name}".to_json }

              it { expect(response.status).to eq(200) }

              it {
                expect(response.body).to be_json_eql(title)
                                           .at_path("_links/#{property}/title")
              }

              it_behaves_like 'lock version updated'
            end

            context 'user' do
              let(:user_href) { api_v3_paths.user user.id }

              include_context 'patch request'

              it_behaves_like 'valid user assignment' do
                let(:assigned_user) { user }
              end
            end

            context 'group' do
              let(:user_href) { api_v3_paths.user group.id }

              include_context 'setup group membership', true
              include_context 'patch request'

              it_behaves_like 'valid user assignment' do
                let(:assigned_user) { group }
              end
            end
          end

          describe 'invalid' do
            include_context 'patch request'

            context 'user doesn\'t exist' do
              let(:user_href) { api_v3_paths.user 909090 }

              it_behaves_like 'constraint violation' do
                let(:message) do
                  I18n.t('api_v3.errors.validation.' \
                                     'invalid_user_assigned_to_work_package',
                         property: WorkPackage.human_attribute_name(property))
                end
              end
            end

            context 'user is not visible' do
              let(:invalid_user) { FactoryBot.create(:user) }
              let(:user_href) { api_v3_paths.user invalid_user.id }

              it_behaves_like 'constraint violation' do
                let(:message) do
                  I18n.t('api_v3.errors.validation.invalid_user_assigned_to_work_package',
                         property: WorkPackage.human_attribute_name(property))
                end
              end
            end

            context 'wrong resource' do
              let(:user_href) { api_v3_paths.status work_package.status.id }

              include_context 'patch request'

              it_behaves_like 'invalid resource link' do
                let(:message) do
                  I18n.t('api_v3.errors.invalid_resource',
                         property: property,
                         expected: "/api/v3/groups/:id' or '/api/v3/users/:id",
                         actual: user_href)
                end
              end
            end

            context 'group assignment disabled' do
              let(:user_href) { api_v3_paths.user group.id }

              include_context 'setup group membership', false
              include_context 'patch request'

              it_behaves_like 'constraint violation' do
                let(:message) do
                  I18n.t('api_v3.errors.validation.invalid_user_assigned_to_work_package',
                         property: WorkPackage.human_attribute_name(property))
                end
              end
            end
          end
        end

        context 'assingee' do
          it_behaves_like 'handling people', 'assignee'
        end

        context 'responsible' do
          it_behaves_like 'handling people', 'responsible'
        end
      end

      context 'version' do
        let(:target_version) { FactoryBot.create(:version, project: project) }
        let(:version_link) { api_v3_paths.version target_version.id }
        let(:version_parameter) { {_links: {version: {href: version_link}}} }
        let(:params) { valid_params.merge(version_parameter) }

        before { allow(User).to receive(:current).and_return current_user }

        context 'valid' do
          include_context 'patch request'

          it { expect(response.status).to eq(200) }

          it 'should respond with the work package assigned to the version' do
            expect(subject.body)
              .to be_json_eql(target_version.name.to_json)
              .at_path('_embedded/version/name')
          end

          it_behaves_like 'lock version updated'
        end

        context 'for a user lacking the assign_versions permission' do
          let(:permissions) { %i[view_work_packages edit_work_packages] }

          include_context 'patch request'

          it { expect(response.status).to eq(422) }

          it 'has a readonly error' do
            expect(response.body)
              .to be_json_eql('urn:openproject-org:api:v3:errors:PropertyIsReadOnly'.to_json)
              .at_path('errorIdentifier')
          end
        end
      end

      context 'category' do
        let(:target_category) { FactoryBot.create(:category, project: project) }
        let(:category_link) { api_v3_paths.category target_category.id }
        let(:category_parameter) { {_links: {category: {href: category_link}}} }
        let(:params) { valid_params.merge(category_parameter) }

        before { allow(User).to receive(:current).and_return current_user }

        context 'valid' do
          include_context 'patch request'

          it { expect(response.status).to eq(200) }

          it 'should respond with the work package assigned to the category' do
            expect(subject.body)
              .to be_json_eql(target_category.name.to_json)
              .at_path('_embedded/category/name')
          end

          it_behaves_like 'lock version updated'
        end
      end

      context 'priority' do
        let(:target_priority) { FactoryBot.create(:priority) }
        let(:priority_link) { api_v3_paths.priority target_priority.id }
        let(:priority_parameter) { {_links: {priority: {href: priority_link}}} }
        let(:params) { valid_params.merge(priority_parameter) }

        before { allow(User).to receive(:current).and_return current_user }

        context 'valid' do
          include_context 'patch request'

          it { expect(response.status).to eq(200) }

          it 'should respond with the work package assigned to the priority' do
            expect(subject.body)
              .to be_json_eql(target_priority.name.to_json)
              .at_path('_embedded/priority/name')
          end

          it_behaves_like 'lock version updated'
        end
      end

      context 'list custom field' do
        let(:custom_field) do
          FactoryBot.create(:list_wp_custom_field)
        end

        let(:target_value) { custom_field.possible_values.last }

        let(:value_link) do
          api_v3_paths.custom_option target_value.id
        end

        let(:value_parameter) do
          {_links: {custom_field.accessor_name.camelize(:lower) => {href: value_link}}}
        end
        let(:params) { valid_params.merge(value_parameter) }

        before do
          allow(User).to receive(:current).and_return current_user
          work_package.project.work_package_custom_fields << custom_field
          work_package.type.custom_fields << custom_field
        end

        context 'valid' do
          include_context 'patch request'

          it { expect(response.status).to eq(200) }

          it 'should respond with the work package assigned to the new value' do
            expect(subject.body)
              .to be_json_eql(value_link.to_json)
              .at_path("_links/#{custom_field.accessor_name.camelize(:lower)}/href")
          end

          it_behaves_like 'lock version updated'
        end
      end

      describe 'update with read-only attributes' do
        describe 'single read-only violation' do
          context 'created and updated' do
            let(:tomorrow) { (DateTime.now + 1.day).utc.iso8601 }
            include_context 'patch request'

            context 'created_at' do
              let(:params) { valid_params.merge(createdAt: tomorrow) }

              it_behaves_like 'read-only violation', 'createdAt', WorkPackage, 'Created on'
            end

            context 'updated_at' do
              let(:params) { valid_params.merge(updatedAt: tomorrow) }

              it_behaves_like 'read-only violation', 'updatedAt', WorkPackage, 'Updated on'
            end
          end
        end

        context 'multiple read-only attributes' do
          let(:params) do
            valid_params.merge(createdAt: Date.today.iso8601, updatedAt: Date.today.iso8601)
          end

          include_context 'patch request'

          it_behaves_like 'multiple errors', 422

          it_behaves_like 'multiple errors of the same type', 2, 'PropertyIsReadOnly'

          it_behaves_like 'multiple errors of the same type with details',
                          'attribute',
                          'attribute' => ['createdAt', 'updatedAt']
        end
      end

      context 'invalid update' do
        context 'single invalid attribute' do
          let(:params) { valid_params.tap { |h| h[:subject] = '' } }

          include_context 'patch request'

          it_behaves_like 'constraint violation' do
            let(:message) { "Subject can't be blank" }
          end
        end

        context 'multiple invalid attributes' do
          let(:params) do
            valid_params
              .tap { |h| h[:subject] = '' }
              .merge(
                _links: {
                  parent: {
                    href: api_v3_paths.work_package("-123")
                  }
                }
              )
          end

          before do
            role.add_permission!(:manage_subtasks)
          end

          include_context 'patch request'

          it_behaves_like 'multiple errors', 422

          it_behaves_like 'multiple errors of the same type', 2, 'PropertyConstraintViolation'

          it_behaves_like 'multiple errors of the same type with messages' do
            let(:message) { ['Subject can\'t be blank.', 'Parent does not exist.'] }
          end
        end

        context 'missing lock version' do
          let(:params) { valid_params.except(:lockVersion) }

          include_context 'patch request'

          it_behaves_like 'update conflict'
        end

        context 'stale object' do
          let(:params) { valid_params.merge(subject: 'Updated subject') }

          before do
            params

            work_package.subject = 'I am the first!'
            work_package.save!

            expect(valid_params[:lockVersion]).not_to eq(work_package.lock_version)
          end

          include_context 'patch request'

          it_behaves_like 'update conflict'
        end
      end

      context 'claiming attachments' do
        let(:old_attachment) { FactoryBot.create(:attachment, container: work_package) }
        let(:attachment) { FactoryBot.create(:attachment, container: nil, author: current_user) }
        let(:params) do
          {
            lockVersion: work_package.lock_version,
            _links: {
              attachments: [
                href: api_v3_paths.attachment(attachment.id)
              ]
            }
          }
        end

        before do
          old_attachment
        end

        include_context 'patch request'

        it 'replaces the current with the provided attachments' do
          work_package.reload

          expect(work_package.attachments)
            .to match_array(attachment)
        end
      end
    end
  end

  describe 'DELETE /api/v3/work_packages/:id' do
    let(:path) { api_v3_paths.work_package work_package.id }

    before do
      delete path
    end

    subject { last_response }

    context 'with required permissions' do
      let(:permissions) { %i[view_work_packages delete_work_packages] }

      it 'responds with HTTP No Content' do
        expect(subject.status).to eq 204
      end

      it 'deletes the work package' do
        expect(WorkPackage.exists?(work_package.id)).to be_falsey
      end

      context 'for a non-existent work package' do
        let(:path) { api_v3_paths.work_package 1337 }

        it_behaves_like 'not found' do
          let(:id) { 1337 }
          let(:type) { 'WorkPackage' }
        end
      end
    end

    context 'without permission to see work packages' do
      let(:permissions) { [] }

      it_behaves_like 'not found'
    end

    context 'without permission to delete work packages' do
      let(:permissions) { [:view_work_packages] }

      it_behaves_like 'unauthorized access'

      it 'does not delete the work package' do
        expect(WorkPackage.exists?(work_package.id)).to be_truthy
      end
    end
  end

  describe 'POST /api/v3/work_packages' do
    let(:path) { api_v3_paths.work_packages }
    let(:permissions) { %i[add_work_packages view_project] }
    let(:status) { FactoryBot.build(:status, is_default: true) }
    let(:priority) { FactoryBot.build(:priority, is_default: true) }
    let(:type) { project.types.first }
    let(:parameters) do
      {
        subject: 'new work packages',
        _links: {
          type: {
            href: api_v3_paths.type(type.id)
          },
          project: {
            href: api_v3_paths.project(project.id)
          }
        }
      }
    end

    before do
      status.save!
      priority.save!

      FactoryBot.create(:user_preference, user: current_user, others: {no_self_notified: false})
      post path, parameters.to_json, 'CONTENT_TYPE' => 'application/json'
      perform_enqueued_jobs
    end

    context 'notifications' do
      let(:permissions) { %i[add_work_packages view_project view_work_packages] }

      it 'sends a mail by default' do
        expect(DeliverWorkPackageNotificationJob)
          .to have_been_enqueued
          .at_least(1)
      end

      context 'without notifications' do
        let(:path) { "#{api_v3_paths.work_packages}?notify=false" }

        it 'should not send a mail' do
          expect(DeliverWorkPackageNotificationJob).not_to have_been_enqueued
        end
      end

      context 'with notifications' do
        let(:path) { "#{api_v3_paths.work_packages}?notify=true" }

        it 'should send a mail' do
          expect(DeliverWorkPackageNotificationJob)
            .to have_been_enqueued
            .at_least(1)
        end
      end
    end

    it 'should return Created(201)' do
      expect(last_response.status).to eq(201)
    end

    it 'should create a work package' do
      expect(WorkPackage.all.count).to eq(1)
    end

    it 'should use the given parameters' do
      expect(WorkPackage.first.subject).to eq(parameters[:subject])
    end

    it 'should be associated with the provided project' do
      expect(WorkPackage.first.project).to eq(project)
    end

    it 'should be associated with the provided type' do
      expect(WorkPackage.first.type).to eq(type)
    end

    context 'no permissions' do
      let(:current_user) { FactoryBot.create(:user) }

      it 'should hide the endpoint' do
        expect(last_response.status).to eq(403)
      end
    end

    context 'view_project permission' do
      # Note that this just removes the add_work_packages permission
      # view_project is actually provided by being a member of the project
      let(:permissions) { [:view_project] }

      it 'should point out the missing permission' do
        expect(last_response.status).to eq(403)
      end
    end

    context 'empty parameters' do
      let(:parameters) { {} }

      it_behaves_like 'multiple errors', 422

      it 'should not create a work package' do
        expect(WorkPackage.all.count).to eq(0)
      end
    end

    context 'bogus parameters' do
      let(:parameters) do
        {
          bogus: 'bogus',
          _links: {
            type: {
              href: api_v3_paths.type(project.types.first.id)
            },
            project: {
              href: api_v3_paths.project(project.id)
            }
          }
        }
      end

      it_behaves_like 'constraint violation' do
        let(:message) { "Subject can't be blank" }
      end

      it 'should not create a work package' do
        expect(WorkPackage.all.count).to eq(0)
      end
    end

    context 'schedule manually' do
      let(:work_package) { WorkPackage.first }

      context 'with true' do
        # mind the () for the super call, those are required in rspec's super
        let(:parameters) { super().merge(scheduleManually: true) }

        it 'should set the scheduling mode to true' do
          expect(work_package.schedule_manually).to eq true
        end
      end

      context 'with false' do
        let(:parameters) { super().merge(scheduleManually: false) }

        it 'should set the scheduling mode to false' do
          expect(work_package.schedule_manually).to eq false
        end
      end

      context 'with scheduleManually absent' do
        it 'should set the scheduling mode to false (default)' do
          expect(work_package.schedule_manually).to eq false
        end
      end
    end

    context 'invalid value' do
      let(:parameters) do
        {
          subject: nil,
          _links: {
            type: {
              href: api_v3_paths.type(project.types.first.id)
            },
            project: {
              href: api_v3_paths.project(project.id)
            }
          }
        }
      end

      it_behaves_like 'constraint violation' do
        let(:message) { "Subject can't be blank" }
      end

      it 'should not create a work package' do
        expect(WorkPackage.all.count).to eq(0)
      end
    end

    context 'claiming attachments' do
      let(:attachment) { FactoryBot.create(:attachment, container: nil, author: current_user) }
      let(:parameters) do
        {
          subject: 'subject',
          _links: {
            type: {
              href: api_v3_paths.type(project.types.first.id)
            },
            project: {
              href: api_v3_paths.project(project.id)
            },
            attachments: [
              href: api_v3_paths.attachment(attachment.id)
            ]
          }
        }
      end

      it 'creates the work package and assigns the attachments' do
        expect(WorkPackage.all.count).to eq(1)

        work_package = WorkPackage.last

        expect(work_package.attachments)
          .to match_array(attachment)
      end
    end
  end
end
