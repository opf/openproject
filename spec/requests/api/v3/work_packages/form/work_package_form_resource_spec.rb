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

describe 'API v3 Work package form resource', type: :request do
  include Rack::Test::Methods
  include Capybara::RSpecMatchers

  let(:project) { FactoryGirl.create(:project, is_public: false) }
  let(:work_package) { FactoryGirl.create(:work_package, project: project) }
  let(:authorized_user) { FactoryGirl.create(:user, member_in_project: project) }
  let(:unauthorized_user) { FactoryGirl.create(:user) }

  describe '#post' do
    let(:post_path) { "/api/v3/work_packages/#{work_package.id}/form" }
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
        post post_path, params.to_json, 'CONTENT_TYPE' => 'application/json'
      end
    end

    context 'user without needed permissions' do
      let(:work_package) { FactoryGirl.create(:work_package, id: 42, project: project) }
      let(:params) { {} }

      include_context 'post request' do
        let(:current_user) { unauthorized_user }
      end

      it_behaves_like 'not found', 42, 'WorkPackage'
    end

    context 'user with needed permissions' do
      let(:params) {}
      let(:current_user) { authorized_user }

      context 'non-existing work package' do
        let(:post_path) { '/api/v3/work_packages/eeek/form' }

        include_context 'post request'

        it_behaves_like 'not found', 'eeek', 'WorkPackage'
      end

      context 'existing work package' do
        shared_examples_for 'valid payload' do
          it { expect(response.status).to eq(200) }

          it { expect(subject.body).to have_json_path('_embedded/payload') }

          it { expect(subject.body).to have_json_path('_embedded/payload/lockVersion') }

          it { expect(subject.body).to have_json_path('_embedded/payload/subject') }

          it { expect(subject.body).to have_json_path('_embedded/payload/rawDescription') }
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

          it {
            expect(subject.body).to be_json_eql(work_package.description.to_json)
              .at_path('_embedded/payload/rawDescription')
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

            let(:error_body) {
              parse_json(subject.body)['_embedded']['validationErrors'][property]
            }

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

                it { expect(response.status).to eq(409) }

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
              let(:path) { '_embedded/payload/rawDescription' }
              let(:description) { '*Some text* _describing_ *something*...' }
              let(:params) { valid_params.merge(rawDescription: description) }

              include_context 'post request'

              it_behaves_like 'valid payload'

              it_behaves_like 'having no errors'

              it 'should respond with updated work package description' do
                expect(subject.body).to be_json_eql(description.to_json).at_path(path)
              end
            end

            describe 'status' do
              let(:path) { '_embedded/payload/_links/status/href' }
              let(:target_status) { FactoryGirl.create(:status) }
              let(:status_link) { "/api/v3/statuses/#{target_status.id}" }
              let(:status_parameter) { { _links: { status: { href: status_link } } } }
              let(:params) { valid_params.merge(status_parameter) }

              context 'valid status' do
                let!(:workflow) {
                  FactoryGirl.create(:workflow,
                                     type_id: work_package.type.id,
                                     old_status: work_package.status,
                                     new_status: target_status,
                                     role: current_user.memberships[0].roles[0])
                }

                include_context 'post request'

                it_behaves_like 'valid payload'

                it_behaves_like 'having no errors'

                it 'should respond with updated work package status' do
                  expect(subject.body).to be_json_eql(status_link.to_json).at_path(path)
                end
              end

              context 'invalid status' do
                context 'no transition' do
                  include_context 'post request'

                  it_behaves_like 'valid payload'

                  it_behaves_like 'having an error', 'status_id'

                  it 'should respond with updated work package status' do
                    expect(subject.body).to be_json_eql(status_link.to_json).at_path(path)
                  end
                end

                context 'status does not exist' do
                  let(:status_link) { '/api/v3/statuses/-1' }

                  include_context 'post request'

                  it_behaves_like 'valid payload'

                  it_behaves_like 'having an error', 'status_id'

                  it 'should respond with updated work package status' do
                    expect(subject.body).to be_json_eql(status_link.to_json).at_path(path)
                  end
                end

                context 'wrong resource' do
                  let(:status_link) { "/api/v3/users/#{authorized_user.id}" }

                  include_context 'post request'

                  it_behaves_like 'constraint violation',
                                  'For property status a resource of type Status' \
                                  ' is expected but got a resource of type User.'
                end
              end
            end

            describe 'assignee and responsible' do
              shared_examples_for 'handling people' do |property|
                let(:path) { "_embedded/payload/_links/#{property}/href" }
                let(:visible_user) {
                  FactoryGirl.create(:user,
                                     member_in_project: project)
                }
                let(:user_parameter) { { _links: { property => { href: user_link } } } }
                let(:params) { valid_params.merge(user_parameter) }

                context "valid #{property}" do
                  let(:user_link) { "/api/v3/users/#{visible_user.id}" }

                  include_context 'post request'

                  it_behaves_like 'valid payload'

                  it_behaves_like 'having no errors'

                  it "should respond with updated work package #{property}" do
                    expect(subject.body).to be_json_eql(user_link.to_json).at_path(path)
                  end
                end

                context "invalid #{property}" do
                  context 'non-existing user' do
                    let(:user_link) { '/api/v3/users/42' }

                    include_context 'post request'

                    it_behaves_like 'valid payload'

                    it_behaves_like 'having an error', property

                    it "should respond with updated work package #{property}" do
                      expect(subject.body).to be_json_eql(user_link.to_json).at_path(path)
                    end
                  end

                  context 'wrong resource' do
                    let(:user_link) { "/api/v3/statuses/#{work_package.status.id}" }

                    include_context 'post request'

                    it_behaves_like 'constraint violation',
                                    "For property #{property} a resource of type User" \
                                    ' is expected but got a resource of type Status.'
                  end
                end
              end

              it_behaves_like 'handling people', 'assignee'

              it_behaves_like 'handling people', 'responsible'
            end
          end
        end
      end
    end
  end
end
