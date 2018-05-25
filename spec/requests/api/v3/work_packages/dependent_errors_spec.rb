#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'
require 'rack/test'

describe 'API v3 Work package resource', type: :request, content_type: :json do
  include Rack::Test::Methods
  include Capybara::RSpecMatchers
  include API::V3::Utilities::PathHelper

  let(:work_package) do
    FactoryGirl.create(
      :work_package,
      project_id: project.id,
      parent: parent,
      subject: "Updated WorkPackage"
    )
  end

  let!(:parent) do
    FactoryGirl.create(:work_package, project_id: project.id, type: type, subject: "Invalid Dependent WorkPackage").tap do |parent|
      parent.custom_values.create custom_field: custom_field, value: custom_field.possible_values.first.id

      cv = parent.custom_values.last
      cv.update_column :value, "0"
    end
  end

  let(:project) do
    FactoryGirl.create(:project, identifier: 'deperr', is_public: false).tap do |project|
      project.types << type
    end
  end

  let(:type) do
    FactoryGirl.create(:type).tap do |type|
      type.custom_fields << custom_field
    end
  end

  let(:status) { FactoryGirl.create :status }

  let(:custom_field) do
    FactoryGirl.create(
      :list_wp_custom_field,
      name: "Gate",
      possible_values: %w(A B C),
      is_required: true
    )
  end

  let(:role) { FactoryGirl.create(:role, permissions: permissions) }
  let(:permissions) { [:view_work_packages, :edit_work_packages, :create_work_packages] }

  let(:current_user) do
    user = FactoryGirl.create(:user, member_in_project: project, member_through_role: role)

    FactoryGirl.create(:user_preference, user: user, others: { no_self_notified: false })

    user
  end

  let(:dependent_error_result) do
    proc do |instance, _attributes, work_package|
      result = ServiceResult.new(success: true, result: instance.work_package || work_package)
      dep = parent
      dep.errors.add :base, "invalid", message: "invalid"

      result.add_dependent!(ServiceResult.new(success: false, errors: dep.errors, result: dep))

      result
    end
  end

  before do
    allow(User).to receive(:current).and_return current_user
  end

  describe '#patch' do
    let(:path) { api_v3_paths.work_package work_package.id }
    let(:valid_params) do
      {
        _type: 'WorkPackage',
        lockVersion: work_package.lock_version
      }
    end

    subject(:response) { last_response }

    shared_context 'patch request' do
      before(:each) do
        patch path, params.to_json, 'CONTENT_TYPE' => 'application/json'
      end
    end

    before do
      allow_any_instance_of(WorkPackages::UpdateService).to receive(:update_dependent, &dependent_error_result)
    end

    context 'attribute' do
      let(:params) { valid_params.merge(startDate: "2018-05-23") }

      include_context 'patch request'

      it { expect(response.status).to eq(422) }

      it 'should respond with an error' do
        expected_error = {
          "_type": "Error",
          "errorIdentifier": "urn:openproject-org:api:v3:errors:PropertyConstraintViolation",
          "message": "Error in dependent work package ##{parent.id} #{parent.subject}: invalid",
          "_embedded": {
            "details": {
              "attribute": "base"
            }
          }
        }

        expect(subject.body).to be_json_eql(expected_error.to_json)
      end
    end
  end

  describe '#post' do
    let(:current_user) { FactoryGirl.create :admin }

    let(:path) { api_v3_paths.work_packages }
    let(:valid_params) do
      {
        _type: 'WorkPackage',
        lockVersion: 0,
        _links: {
          author: { href: "/api/v3/users/#{current_user.id}" },
          project: { href: "/api/v3/projects/#{project.id}" },
          status: { href: "/api/v3/statuses/#{status.id}" },
          priority: { href: "/api/v3/priorities/#{work_package.priority.id}" }
        }
      }
    end

    subject(:response) { last_response }

    shared_context 'post request' do
      before(:each) do
        post path, params.to_json, 'CONTENT_TYPE' => 'application/json'
      end
    end

    before do
      allow_any_instance_of(WorkPackages::CreateService).to receive(:create, &dependent_error_result)
    end

    context 'request' do
      let(:params) { valid_params.merge(subject: "Test Subject") }

      include_context 'post request'

      it { expect(response.status).to eq(422) }

      it 'should respond with an error' do
        expected_error = {
          "_type": "Error",
          "errorIdentifier": "urn:openproject-org:api:v3:errors:PropertyConstraintViolation",
          "message": "Error in dependent work package ##{parent.id} #{parent.subject}: invalid",
          "_embedded": {
            "details": {
              "attribute": "base"
            }
          }
        }

        expect(subject.body).to be_json_eql(expected_error.to_json)
      end
    end
  end
end
