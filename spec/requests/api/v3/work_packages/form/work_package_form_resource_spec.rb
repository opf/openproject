#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2018 the OpenProject Foundation (OPF)
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

describe 'API v3 Work package form resource', type: :request do
  include Rack::Test::Methods
  include Capybara::RSpecMatchers
  include API::V3::Utilities::PathHelper

  shared_let(:project) { FactoryBot.create(:project, is_public: false) }
  shared_let(:work_package, reload: true) { FactoryBot.create(:work_package, project: project) }
  shared_let(:authorized_user) { FactoryBot.create(:user, member_in_project: project) }
  shared_let(:unauthorized_user) { FactoryBot.create(:user) }

  describe '#post' do
    let(:post_path) { api_v3_paths.work_package_form work_package.id }
    let(:valid_params) do
      {
        _type: 'WorkPackage',
        lockVersion: work_package.lock_version
      }
    end

    subject(:response) { last_response }

    shared_context 'post request' do
      before(:each) do
        allow(User).to receive(:current).and_return current_user
        post post_path, (params ? params.to_json : nil), 'CONTENT_TYPE' => 'application/json'
      end
    end

    context 'user without needed permissions' do
      let(:params) { {} }

      include_context 'post request' do
        let(:current_user) { unauthorized_user }
      end

      it_behaves_like 'not found'
    end

    context 'user with needed permissions' do
      let(:params) {}
      let(:current_user) { authorized_user }

      context 'non-existing work package' do
        let(:post_path) { api_v3_paths.work_package_form 'eeek' }

        include_context 'post request'

        it_behaves_like 'not found' do
          let(:id) { 'eeek' }
          let(:type) { 'WorkPackage' }
        end
      end

      context 'existing work package' do
        shared_examples_for 'valid payload' do
          subject { last_response.body }

          it { expect(last_response.status).to eq(200) }

          it { is_expected.to have_json_path('_embedded/payload') }

          it { is_expected.to have_json_path('_embedded/payload/lockVersion') }

          it { is_expected.to have_json_path('_embedded/payload/subject') }

          it_behaves_like 'API V3 formattable', '_embedded/payload/description' do
            let(:format) { 'markdown' }
            let(:raw) { defined?(raw_value) ? raw_value : work_package.description.to_s }
            let(:html) do
              defined?(html_value) ? html_value : ('<p>' + work_package.description.to_s + '</p>')
            end
          end
        end

        shared_examples_for 'valid payload with initial values' do
          it {
            expect(subject.body).to be_json_eql(work_package.lock_version.to_json)
              .at_path('_embedded/payload/lockVersion')
          }

          it {
            expect(subject.body).to be_json_eql(work_package.subject.to_json)
              .at_path('_embedded/payload/subject')
          }
        end

        shared_examples_for 'having no errors' do
          it {
            expect(subject.body).to be_json_eql({}.to_json)
              .at_path('_embedded/validationErrors')
          }
        end

        shared_examples_for 'having an error' do |property|
          it { expect(subject.body).to have_json_path("_embedded/validationErrors/#{property}") }

          describe 'error body' do
            let(:error_id) { 'urn:openproject-org:api:v3:errors:PropertyConstraintViolation' }

            let(:error_body) { parse_json(subject.body)['_embedded']['validationErrors'][property] }

            it { expect(error_body['errorIdentifier']).to eq(error_id) }
          end
        end

        describe 'body' do
          context 'empty' do
            include_context 'post request'

            it_behaves_like 'valid payload'

            it_behaves_like 'valid payload with initial values'

            it_behaves_like 'having no errors'
          end

          context 'filled' do
            let(:valid_params) do
              {
                _type: 'WorkPackage',
                lockVersion: work_package.lock_version
              }
            end

            describe 'no change' do
              let(:params) { valid_params }

              include_context 'post request'

              it_behaves_like 'valid payload'

              it_behaves_like 'valid payload with initial values'

              it_behaves_like 'having no errors'
            end

            context 'invalid content' do
              before do
                allow(User).to receive(:current).and_return current_user
                post post_path, '{ ,', 'CONTENT_TYPE' => 'application/json; charset=utf-8'
              end

              it_behaves_like 'parse error',
                              'unexpected comma at line 1, column 3'
            end

            describe 'lock version' do
              context 'missing lock version' do
                let(:params) { valid_params.except(:lockVersion) }

                include_context 'post request'

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

                include_context 'post request'

                it { expect(last_response.status).to eq(409) }

                it_behaves_like 'update conflict'
              end
            end

            describe 'subject' do
              include_context 'post request'

              context 'valid subject' do
                let(:params) { valid_params.merge(subject: 'Updated subject') }

                it_behaves_like 'valid payload'

                it_behaves_like 'having no errors'

                it 'should respond with updated work package subject' do
                  expect(subject.body).to be_json_eql('Updated subject'.to_json)
                    .at_path('_embedded/payload/subject')
                end
              end

              context 'invalid subject' do
                let(:params) { valid_params.merge(subject: nil) }

                it_behaves_like 'valid payload'

                it_behaves_like 'having an error', 'subject'

                it 'should respond with updated work package subject' do
                  expect(subject.body).to be_json_eql(nil.to_json)
                    .at_path('_embedded/payload/subject')
                end
              end
            end

            describe 'description' do
              let(:path) { '_embedded/payload/description/raw' }
              let(:description) { '**Some text** *describing* **something**...' }
              let(:params) { valid_params.merge(description: { raw: description }) }

              include_context 'post request'

              it_behaves_like 'valid payload' do
                let(:raw_value) { description }
                let(:html_value) do
                  '<p><strong>Some text</strong> <em>describing</em> ' \
                  '<strong>something</strong>...</p>'
                end
              end

              it_behaves_like 'having no errors'
            end

            describe 'start date' do
              include_context 'post request'

              context 'valid date' do
                let(:params) { valid_params.merge(startDate: '2015-01-31') }

                it_behaves_like 'valid payload'

                it_behaves_like 'having no errors'

                it 'should respond with updated work package' do
                  expect(subject.body).to be_json_eql('2015-01-31'.to_json)
                    .at_path('_embedded/payload/startDate')
                end
              end

              context 'invalid date' do
                let(:params) { valid_params.merge(startDate: 'not a date') }

                it_behaves_like 'format error',
                                I18n.t('api_v3.errors.invalid_format',
                                       property: 'startDate',
                                       expected_format: I18n.t('api_v3.errors.expected.date'),
                                       actual: 'not a date')
              end
            end

            describe 'due date' do
              include_context 'post request'

              context 'valid date' do
                let(:params) { valid_params.merge(dueDate: '2015-01-31') }

                it_behaves_like 'valid payload'

                it_behaves_like 'having no errors'

                it 'should respond with updated work package' do
                  expect(subject.body).to be_json_eql('2015-01-31'.to_json)
                    .at_path('_embedded/payload/dueDate')
                end
              end

              context 'invalid date' do
                let(:params) { valid_params.merge(dueDate: 'not a date') }

                it_behaves_like 'format error',
                                I18n.t('api_v3.errors.invalid_format',
                                       property: 'dueDate',
                                       expected_format: I18n.t('api_v3.errors.expected.date'),
                                       actual: 'not a date')
              end
            end

            describe 'status' do
              let(:path) { '_embedded/payload/_links/status/href' }
              let(:target_status) { FactoryBot.create(:status) }
              let(:status_link) { api_v3_paths.status target_status.id }
              let(:status_parameter) { { _links: { status: { href: status_link } } } }
              let(:params) { valid_params.merge(status_parameter) }

              context 'valid status' do
                let!(:workflow) do
                  FactoryBot.create(:workflow,
                                    type_id: work_package.type.id,
                                    old_status: work_package.status,
                                    new_status: target_status,
                                    role: current_user.memberships[0].roles[0])
                end

                include_context 'post request'

                it_behaves_like 'valid payload'

                it_behaves_like 'having no errors'

                it 'should respond with updated work package status' do
                  expect(subject.body).to be_json_eql(status_link.to_json).at_path(path)
                end

                it 'should still show the original allowed statuses' do
                  expect(subject.body).to be_json_eql(status_link.to_json)
                    .at_path('_embedded/schema/status/_links/allowedValues/1/href')
                end
              end

              context 'invalid status' do
                context 'no transition' do
                  include_context 'post request'

                  it_behaves_like 'valid payload'

                  it_behaves_like 'having an error', 'status'

                  it 'should respond with updated work package status' do
                    expect(subject.body).to be_json_eql(status_link.to_json).at_path(path)
                  end
                end

                context 'status does not exist' do
                  let(:error_id) do
                    'urn:openproject-org:api:v3:errors:MultipleErrors'.to_json
                  end
                  let(:status_link) { api_v3_paths.status -1 }

                  include_context 'post request'

                  it_behaves_like 'valid payload'

                  it_behaves_like 'having an error', 'status'

                  it 'should respond with updated work package status' do
                    expect(subject.body).to be_json_eql(status_link.to_json).at_path(path)
                  end
                end

                context 'wrong resource' do
                  let(:status_link) { api_v3_paths.user authorized_user.id }

                  include_context 'post request'

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
            end

            describe 'assignee and responsible' do
              shared_context 'setup group membership' do |group_assignment|
                let(:group) { FactoryBot.create(:group) }
                let(:role) { FactoryBot.create(:role) }
                let(:group_member) do
                  FactoryBot.create(:member,
                                    principal: group,
                                    project: project,
                                    roles: [role])
                end

                before do
                  allow(Setting).to receive(:work_package_group_assignment?)
                    .and_return(group_assignment)

                  group_member.save!
                end
              end

              shared_examples_for 'handling people' do |property|
                let(:path) { "_embedded/payload/_links/#{property}/href" }
                let(:visible_user) do
                  FactoryBot.create(:user,
                                    member_in_project: project)
                end
                let(:user_parameter) { { _links: { property => { href: user_link } } } }
                let(:params) { valid_params.merge(user_parameter) }

                shared_examples_for 'having updated work package principal' do
                  it "should respond with updated work package #{property}" do
                    expect(subject.body).to be_json_eql(user_link.to_json).at_path(path)
                  end
                end

                context "valid #{property}" do
                  shared_examples_for 'valid user assignment' do
                    include_context 'post request'

                    it_behaves_like 'valid payload'

                    it_behaves_like 'having no errors'

                    it_behaves_like 'having updated work package principal'
                  end

                  context 'empty user' do
                    let(:user_link) { nil }

                    it_behaves_like 'valid user assignment'
                  end

                  context 'existing user' do
                    let(:user_link) { api_v3_paths.user visible_user.id }

                    it_behaves_like 'valid user assignment'
                  end

                  context 'existing group' do
                    let(:user_link) { api_v3_paths.group group.id }

                    include_context 'setup group membership', true

                    it_behaves_like 'valid user assignment'
                  end
                end

                context "invalid #{property}" do
                  context 'non-existing user' do
                    let(:user_link) { api_v3_paths.user 4200 }

                    include_context 'post request'

                    it_behaves_like 'valid payload'

                    it_behaves_like 'having an error', property

                    it_behaves_like 'having updated work package principal'
                  end

                  context 'wrong resource' do
                    let(:user_link) { api_v3_paths.status work_package.status.id }

                    include_context 'post request'

                    it_behaves_like 'invalid resource link' do
                      let(:message) do
                        I18n.t('api_v3.errors.invalid_resource',
                               property: property,
                               expected: "/api/v3/groups/:id' or '/api/v3/users/:id",
                               actual: user_link)
                      end
                    end
                  end

                  context 'group assignement disabled' do
                    let(:user_link) { api_v3_paths.group group.id }

                    include_context 'setup group membership', false
                    include_context 'post request'

                    it_behaves_like 'invalid resource link' do
                      let(:message) do
                        I18n.t('api_v3.errors.invalid_resource',
                               property: property,
                               expected: "/api/v3/users/:id",
                               actual: user_link)
                      end
                    end
                  end
                end
              end

              it_behaves_like 'handling people', 'assignee'

              it_behaves_like 'handling people', 'responsible'
            end

            describe 'version' do
              let(:path) { '_embedded/payload/_links/version/href' }
              let(:target_version) { FactoryBot.create(:version, project: project) }
              let(:other_version) { FactoryBot.create(:version, project: project) }
              let(:version_link) { api_v3_paths.version target_version.id }
              let(:version_parameter) { { _links: { version: { href: version_link } } } }
              let(:params) { valid_params.merge(version_parameter) }

              describe 'allowed values' do
                before do
                  other_version
                end

                include_context 'post request'

                it 'should list all versions available for the project' do
                  [target_version, other_version].sort.each_with_index do |v, i|
                    expect(subject.body).to be_json_eql(api_v3_paths.version(v.id).to_json)
                      .at_path("_embedded/schema/version/_links/allowedValues/#{i}/href")
                  end
                end
              end

              context 'valid version' do
                include_context 'post request'

                it_behaves_like 'valid payload'

                it_behaves_like 'having no errors'

                it 'should respond with updated work package version' do
                  expect(subject.body).to be_json_eql(version_link.to_json).at_path(path)
                end
              end
            end

            describe 'category' do
              let(:path) { '_embedded/payload/_links/category/href' }
              let(:links_path) { '_embedded/schema/category/_links' }
              let(:target_category) { FactoryBot.create(:category, project: project) }
              let(:other_category) { FactoryBot.create(:category, project: project) }
              let(:category_link) { api_v3_paths.category target_category.id }
              let(:category_parameter) { { _links: { category: { href: category_link } } } }
              let(:params) { valid_params.merge(category_parameter) }

              describe 'allowed values' do
                before do
                  other_category
                end

                include_context 'post request'

                it 'should list the categories' do
                  [target_category, other_category].sort.each_with_index do |c, i|
                    expect(subject.body).to be_json_eql(api_v3_paths.category(c.id).to_json)
                      .at_path("#{links_path}/allowedValues/#{i}/href")
                  end
                end
              end

              context 'valid category' do
                include_context 'post request'

                it_behaves_like 'valid payload'

                it_behaves_like 'having no errors'

                it 'should respond with updated work package category' do
                  expect(subject.body).to be_json_eql(category_link.to_json).at_path(path)
                end
              end
            end

            describe 'priority' do
              let(:path) { '_embedded/payload/_links/priority/href' }
              let(:links_path) { '_embedded/schema/priority/_links' }
              let(:target_priority) { FactoryBot.create(:priority) }
              let(:other_priority) { work_package.priority }
              let(:priority_link) { api_v3_paths.priority target_priority.id }
              let(:other_priority_link) { api_v3_paths.priority other_priority.id }
              let(:priority_parameter) { { _links: { priority: { href: priority_link } } } }
              let(:params) { valid_params.merge(priority_parameter) }

              describe 'allowed values' do
                before do
                  other_priority
                end

                include_context 'post request'

                it 'should list the priorities' do
                  expect(subject.body).to be_json_eql(priority_link.to_json)
                    .at_path("#{links_path}/allowedValues/1/href")
                  expect(subject.body).to be_json_eql(other_priority_link.to_json)
                    .at_path("#{links_path}/allowedValues/0/href")
                end
              end

              context 'valid priority' do
                include_context 'post request'

                it_behaves_like 'valid payload'

                it_behaves_like 'having no errors'

                it 'should respond with updated work package priority' do
                  expect(subject.body).to be_json_eql(priority_link.to_json).at_path(path)
                end
              end
            end

            describe 'type' do
              let(:path) { '_embedded/payload/_links/type/href' }
              let(:links_path) { '_embedded/schema/type/_links' }
              let(:target_type) { FactoryBot.create(:type) }
              let(:other_type) { work_package.type }
              let(:type_link) { api_v3_paths.type target_type.id }
              let(:other_type_link) { api_v3_paths.type other_type.id }
              let(:type_parameter) { { _links: { type: { href: type_link } } } }
              let(:params) { valid_params.merge(type_parameter) }

              before do
                project.types << target_type # make sure we have a valid transition
              end

              describe 'allowed values' do
                before do
                  other_type
                end

                include_context 'post request'

                it 'should list the types' do
                  expect(subject.body).to be_json_eql(type_link.to_json)
                    .at_path("#{links_path}/allowedValues/1/href")
                  expect(subject.body).to be_json_eql(other_type_link.to_json)
                    .at_path("#{links_path}/allowedValues/0/href")
                end
              end

              context 'valid type' do
                include_context 'post request'

                it_behaves_like 'valid payload'

                it_behaves_like 'having no errors'

                it 'should respond with updated work package type' do
                  expect(subject.body).to be_json_eql(type_link.to_json).at_path(path)
                end
              end
            end

            describe 'multiple errors' do
              let(:user_link) { api_v3_paths.user 4200 }
              let(:status_link) { api_v3_paths.status -1 }
              let(:links) do
                {
                  _links: {
                    status: { href: status_link },
                    assignee: { href: user_link },
                    responsible: { href: user_link }
                  }
                }
              end
              let(:params) { valid_params.merge(subject: nil).merge(links) }

              include_context 'post request'

              it_behaves_like 'valid payload'

              it {
                expect(subject.body).to have_json_size(4).at_path('_embedded/validationErrors')
              }

              it { expect(subject.body).to have_json_path('_embedded/validationErrors/subject') }

              it { expect(subject.body).to have_json_path('_embedded/validationErrors/status') }

              it { expect(subject.body).to have_json_path('_embedded/validationErrors/assignee') }

              it {
                expect(subject.body).to have_json_path('_embedded/validationErrors/responsible')
              }
            end
          end
        end
      end
    end
  end
end
