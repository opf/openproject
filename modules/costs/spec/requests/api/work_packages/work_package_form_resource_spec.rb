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

describe 'API v3 Work package form resource', type: :request do
  include Rack::Test::Methods
  include Capybara::RSpecMatchers
  include API::V3::Utilities::PathHelper

  let(:project) { FactoryBot.create(:project, public: false) }
  let(:work_package) { FactoryBot.create(:work_package, project: project) }
  let(:role) { FactoryBot.create(:role, permissions: permissions) }
  let(:authorized_user) do
    FactoryBot.create(:user,
                       member_in_project: project,
                       member_through_role: role)
  end

  let(:permissions) { [:view_work_packages, :edit_work_packages, :view_cost_objects] }

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

    context 'user with needed permissions' do
      let(:params) {}
      let(:current_user) { authorized_user }

      context 'existing work package' do
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
          context 'filled' do
            let(:valid_params) do
              {
                _type: 'WorkPackage',
                lockVersion: work_package.lock_version
              }
            end

            describe 'budget' do
              let(:path) { '_embedded/payload/_links/costObject/href' }
              let(:links_path) { '_embedded/schema/costObject/_links' }
              let(:target_budget) { FactoryBot.create(:cost_object, project: project) }
              let(:other_budget) { FactoryBot.create(:cost_object, project: project) }
              let(:budget_link) { api_v3_paths.budget target_budget.id }
              let(:budget_parameter) { { _links: { costObject: { href: budget_link } } } }
              let(:params) { valid_params.merge(budget_parameter) }

              describe 'allowed values' do
                before do
                  other_budget
                end

                include_context 'post request'

                it 'should list the budgets' do
                  budgets = project.cost_objects

                  budgets.each_with_index do |budget, index|
                    expect(subject.body).to be_json_eql(api_v3_paths.budget(budget.id).to_json)
                      .at_path("#{links_path}/allowedValues/#{index}/href")
                  end
                end
              end

              context 'valid budget' do
                include_context 'post request'

                it_behaves_like 'having no errors'

                it 'should respond with updated work package budget' do
                  expect(subject.body).to be_json_eql(budget_link.to_json).at_path(path)
                end
              end

              context 'invalid budget' do
                let(:target_budget) { FactoryBot.create(:cost_object) }

                include_context 'post request'

                it_behaves_like 'having an error', 'costObject'

                it 'should respond with updated work package budget' do
                  expect(subject.body).to be_json_eql(budget_link.to_json).at_path(path)
                end
              end
            end
          end
        end
      end
    end
  end
end
