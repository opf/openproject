#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2014 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'
require 'rack/test'

describe 'API v3 Work package resource', type: :request do
  include Rack::Test::Methods
  include Capybara::RSpecMatchers

  let(:closed_status) { FactoryGirl.create(:closed_status) }

  let!(:timeline)    { FactoryGirl.create(:timeline,     project_id: project.id) }
  let!(:other_wp)    {
    FactoryGirl.create(:work_package, project_id: project.id,
                                      status: closed_status)
  }
  let(:work_package) {
    FactoryGirl.create(:work_package, project_id: project.id,
                                      description: description
  )
  }
  let(:description) {
    %{
{{>toc}}

h1. OpenProject Masterplan for 2015

h2. three point plan

# One ###{other_wp.id}
# Two
# Three

h3. random thoughts

h4. things we like

* Pointed
* Relaxed
* Debonaire

{{timeline(#{timeline.id})}}
  }}

  let(:project) { FactoryGirl.create(:project, identifier: 'test_project', is_public: false) }
  let(:role) { FactoryGirl.create(:role, permissions: [:view_work_packages, :view_timelines, :edit_work_packages]) }
  let(:current_user) { FactoryGirl.create(:user,  member_in_project: project, member_through_role: role) }
  let(:watcher) do
    FactoryGirl
      .create(:user,  member_in_project: project, member_through_role: role)
      .tap do |user|
        work_package.add_watcher(user)
      end
  end
  let(:unauthorize_user) { FactoryGirl.create(:user) }
  let(:type) { FactoryGirl.create(:type) }

  describe '#get' do
    let(:get_path) { "/api/v3/work_packages/#{work_package.id}" }
    let(:expected_response) do
      {
        '_type' => 'WorkPackage',
        '_links' => {
          'self' => {
            'href' => "http://localhost:3000/api/v3/work_packages/#{work_package.id}",
            'title' => work_package.subject
          }
        },
        'id' => work_package.id,
        'subject' => work_package.subject,
        'type' => work_package.type.name,
        'description' => work_package.description,
        'status' => work_package.status.name,
        'priority' => work_package.priority.name,
        'startDate' => work_package.start_date,
        'dueDate' => work_package.due_date,
        'estimatedTime' => JSON.parse({ units: 'hours', value: work_package.estimated_hours }.to_json),
        'percentageDone' => work_package.done_ratio,
        'versionId' => work_package.fixed_version_id,
        'versionName' => work_package.fixed_version.try(:name),
        'projectId' => work_package.project_id,
        'projectName' => work_package.project.name,
        'responsibleId' => work_package.responsible_id,
        'responsibleName' => work_package.responsible.try(:name),
        'responsibleLogin' => work_package.responsible.try(:login),
        'responsibleMail' => work_package.responsible.try(:mail),
        'assigneeId' => work_package.assigned_to_id,
        'assigneeName' => work_package.assigned_to.try(:name),
        'assigneeLogin' => work_package.assigned_to.try(:login),
        'assigneeMail' => work_package.assigned_to.try(:mail),
        'authorName' => work_package.author.name,
        'authorLogin' => work_package.author.login,
        'authorMail' => work_package.author.mail,
        'createdAt' => work_package.created_at.utc.iso8601,
        'updatedAt' => work_package.updated_at.utc.iso8601
      }
    end

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
          expect(parsed_response['description']).to have_selector("a[href='/work_packages/#{other_wp.id}']")
        end

        it 'should resolve simple macros' do
          expect(parsed_response['description']).to have_text('Table of Contents')
        end

        it 'should not resolve/show complex macros' do
          expect(parsed_response['description']).to have_text('Macro timeline cannot be displayed.')
        end
      end

      context 'requesting nonexistent work package' do
        let(:get_path) { '/api/v3/work_packages/909090' }

        it_behaves_like 'not found', 909090, 'WorkPackage'
      end
    end

    context 'when acting as an user without permission to view work package' do
      before(:each) do
        allow(User).to receive(:current).and_return unauthorize_user
        get get_path
      end

      it_behaves_like 'unauthorized access'
    end

    context 'when acting as an anonymous user' do
      before(:each) do
        allow(User).to receive(:current).and_return User.anonymous
        get get_path
      end

      it_behaves_like 'unauthorized access'
    end

  end

  # disabled the its below because the implementation was temporarily disabled
  describe '#patch' do
    let(:patch_path) { "/api/v3/work_packages/#{work_package.id}" }
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
        let(:work_package) { FactoryGirl.create(:work_package, id: 42) }
        let(:current_user) { FactoryGirl.create :user }
        let(:params) { valid_params }

        include_context 'patch request'

        it_behaves_like 'not found', 42, 'WorkPackage'
      end

      context 'no permission to edit the work package' do
        let(:role) { FactoryGirl.create(:role, permissions: [:view_work_packages]) }
        let(:current_user) {
          FactoryGirl.create(:user,
                             member_in_project: work_package.project,
                             member_through_role: role)
        }
        let(:params) { valid_params }

        include_context 'patch request'

        it_behaves_like 'unauthorized access'
      end
    end

    context 'user with needed permissions' do
      shared_examples_for 'lock version updated' do
        it {
          expect(subject.body).to be_json_eql(work_package.reload.lock_version)
            .at_path('lockVersion')
        }
      end

      describe 'notification' do
        let(:update_params) { valid_params.merge(subject: 'Updated subject') }

        before(:each) do
          allow(User).to receive(:current).and_return current_user
          work_package
          ActionMailer::Base.deliveries.clear
        end

        include_context 'patch request'

        subject { ActionMailer::Base.deliveries }

        context 'not set' do
          let(:params) { update_params }

          it { expect(subject.count).to eq(1) }
        end

        context 'disabled' do
          let(:params) { update_params.merge(notify: 'false') }

          it { expect(subject).to be_empty }
        end

        context 'enabled' do
          let(:params) { update_params.merge(notify: 'Some text here - you can take true too') }

          it { expect(subject.count).to eq(1) }
        end
      end

      context 'parent id' do
        let(:parent) { FactoryGirl.create(:work_package, project: work_package.project) }
        let(:params) { valid_params.merge(parentId: parent.id) }

        before { allow(Setting).to receive(:cross_project_work_package_relations?).and_return(true) }

        context 'w/o permission' do
          include_context 'patch request'

          it { expect(response.status).to eq(403) }
        end

        context 'with permission' do
          before { role.add_permission!(:manage_subtasks) }

          include_context 'patch request'

          context 'invalid parent' do
            let(:params) { valid_params.merge(parentId: '-123') }

            it { expect(WorkPackage.visible(current_user).exists?('-123')).to be_falsey }

            it { expect(response.status).to eq(422) }
          end

          context 'empty id' do
            let(:params) { valid_params.merge(parentId: nil) }

            it { expect(response.status).to eq(200) }

            it { expect(subject.body).not_to have_json_path('parentId') }

            it_behaves_like 'lock version updated'
          end

          context 'valid id' do
            let(:params) { valid_params.merge(parentId: parent.id) }

            it { expect(response.status).to eq(200) }

            it { expect(subject.body).to be_json_eql(parent.id.to_json).at_path('parentId') }

            it_behaves_like 'lock version updated'
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
      end

      context 'description' do
        shared_examples_for 'description updated' do |description|
          it 'should respond with updated work package description' do
            expect(subject.body).to be_json_eql(description.to_json).at_path('description')
          end

          it_behaves_like 'lock version updated'
        end

        context 'w/o value (empty)' do
          let(:params) { valid_params.merge(rawDescription: nil) }

          include_context 'patch request'

          it { expect(response.status).to eq(200) }

          it_behaves_like 'description updated', ''
        end

        context 'with value' do
          let(:params) { valid_params.merge(rawDescription: '*Some text* _describing_ *something*...') }

          include_context 'patch request'

          it { expect(response.status).to eq(200) }

          it_behaves_like 'description updated', '<p><strong>Some text</strong> <em>describing</em> <strong>something</strong>...</p>'
        end
      end

      context 'status' do
        let(:target_status) { FactoryGirl.create(:status) }
        let(:status_link) { "/api/v3/statuses/#{target_status.id}" }
        let(:status_parameter) { { _links: { status: { href: status_link } } } }
        let(:params) { valid_params.merge(status_parameter) }

        before { allow(User).to receive(:current).and_return current_user }

        context 'valid status' do
          let!(:workflow) {
            FactoryGirl.create(:workflow,
                               type_id: work_package.type.id,
                               old_status: work_package.status,
                               new_status: target_status,
                               role: current_user.memberships[0].roles[0])
          }

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

          it_behaves_like 'constraint violation',
                          'Status no valid transition exists from old to new '\
                          'status for the current user roles.'
        end

        context 'wrong resource' do
          let(:status_link) { "/api/v3/users/#{current_user.id}" }

          include_context 'patch request'

          it_behaves_like 'constraint violation',
                          'For property status a resource of type Status' \
                          ' is expected but got a resource of type User.'
        end
      end

      context 'assignee and responsible' do
        let(:user) { FactoryGirl.create(:user, member_in_project: project) }
        let(:params) { valid_params.merge(user_parameter) }
        let(:work_package) {
          FactoryGirl.create(:work_package,
                             project: project,
                             assigned_to: current_user,
                             responsible: current_user)
        }

        before { allow(User).to receive(:current).and_return current_user }

        shared_examples_for 'handling people' do |property|
          let(:user_parameter) { { _links: { property => { href: user_href } } } }

          describe 'nil' do
            let(:user_href) { nil }

            include_context 'patch request'

            it { expect(response.status).to eq(200) }

            it { expect(response.body).not_to have_json_path("_links/#{property}") }

            it_behaves_like 'lock version updated'
          end

          describe 'valid' do
            let(:user_href) { "/api/v3/users/#{user.id}" }

            include_context 'patch request'

            it { expect(response.status).to eq(200) }

            it {
              expect(response.body).to be_json_eql("#{user.name} - #{user.login}".to_json)
                .at_path("_links/#{property}/title")
            }

            it_behaves_like 'lock version updated'
          end

          describe 'invalid' do
            include_context 'patch request'

            context 'user doesn\'t exist' do
              let(:user_href) { '/api/v3/users/909090' }

              it_behaves_like 'constraint violation',
                              "#{property.capitalize} is not included in the list"
            end

            context 'user is not visible' do
              let(:invalid_user) { FactoryGirl.create(:user, id: 42) }
              let(:user_href) { '/api/v3/users/42' }

              it_behaves_like 'constraint violation',
                              "#{property.capitalize} is not included in the list"
            end

            context 'wrong resource' do
              let(:user_href) { "/api/v3/statuses/#{work_package.status.id}" }

              include_context 'patch request'

              it_behaves_like 'constraint violation',
                              "For property #{property} a resource of type User" \
                              ' is expected but got a resource of type Status.'
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

      describe 'update with read-only attributes' do
        describe 'single read-only violation' do
          context 'start date' do
            let(:params) { valid_params.merge(startDate: DateTime.now.utc.iso8601) }

            include_context 'patch request'

            it_behaves_like 'read-only violation', 'startDate'
          end

          context 'due date' do
            let(:params) { valid_params.merge(dueDate: DateTime.now.utc.iso8601) }

            include_context 'patch request'

            it_behaves_like 'read-only violation', 'dueDate'
          end

          context 'created and updated' do
            let(:tomorrow) { (DateTime.now + 1.day).utc.iso8601 }
            include_context 'patch request'

            context 'created_at' do
              let(:params) { valid_params.merge(createdAt: tomorrow) }

              it_behaves_like 'read-only violation', 'createdAt'
            end

            context 'updated_at' do
              let(:params) { valid_params.merge(updatedAt: tomorrow) }

              it_behaves_like 'read-only violation', 'updatedAt'
            end
          end

          context 'project id' do
            let(:another_project) { FactoryGirl.create(:project) }
            let!(:another_membership) {
              FactoryGirl.create(:member,
                                 user: current_user,
                                 project: another_project,
                                 roles: [role])
            }
            let(:params) { valid_params.merge(projectId: another_project.id) }

            include_context 'patch request'

            it { expect(response.status).to eq(422) }

            it_behaves_like 'read-only violation', 'projectId'
          end

          context 'fixed version id' do
            let(:params) { valid_params.merge(versionId: -1) }

            include_context 'patch request'

            it_behaves_like 'read-only violation', 'fixedVersionId'
          end
        end

        context 'multiple read-only attributes' do
          let(:params) do
            valid_params.merge(startDate: DateTime.now.utc.iso8601, dueDate: DateTime.now.utc.iso8601)
          end

          include_context 'patch request'

          it_behaves_like 'multiple errors', 422, 'You must not write a read-only attribute'

          it_behaves_like 'multiple errors of the same type', 2, 'PropertyIsReadOnly'

          it_behaves_like 'multiple errors of the same type with details',
                          'attribute',
                          'attribute' => ['startDate', 'dueDate']
        end
      end

      context 'valid update' do
        xit 'should respond with updated work package priority' do
          expect(subject.body).to be_json_eql(params[:priority].to_json).at_path('priority')
        end

        xit 'should update the dates in iso8601 format' do
          expect(subject.body).to be_json_eql(params[:startDate].to_json).at_path('startDate')
          expect(subject.body).to be_json_eql(params[:dueDate].to_json).at_path('dueDate')
        end
      end

      context 'invalid update' do
        context 'single invalid attribute' do
          let(:params) { valid_params.tap { |h| h[:subject] = '' } }

          include_context 'patch request'

          it_behaves_like 'constraint violation', "Subject can't be blank"
        end

        context 'multiple invalid attributes' do
          let(:params) do
            valid_params.tap { |h| h[:subject] = '' }
              .merge(parentId: '-123')
          end

          before { role.add_permission!(:manage_subtasks) }

          include_context 'patch request'

          it_behaves_like 'multiple errors', 422, 'Multiple fields violated their constraints.'

          it_behaves_like 'multiple errors of the same type', 2, 'PropertyConstraintViolation'

          it_behaves_like 'multiple errors of the same type with messages', ['Subject can\'t be blank.', 'Parent does not exist.']
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
    end
  end
end
