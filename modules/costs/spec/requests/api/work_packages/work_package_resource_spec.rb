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

describe 'API v3 Work package resource', type: :request do
  include Rack::Test::Methods
  include Capybara::RSpecMatchers
  include API::V3::Utilities::PathHelper

  let(:work_package) {
    FactoryBot.create(:work_package, project: project)
  }

  let(:project) do
    FactoryBot.create(:project, identifier: 'test_project', public: false)
  end
  let(:role) do
    FactoryBot.create(:role, permissions: [:view_work_packages, :edit_work_packages, :view_cost_objects])
  end
  let(:current_user) do
    FactoryBot.create(:user, member_in_project: project, member_through_role: role)
  end

  describe '#patch' do
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

    context 'user with needed permissions' do
      context 'budget' do
        let(:target_budget) { FactoryBot.create(:cost_object, project: project) }
        let(:budget_link) { api_v3_paths.budget target_budget.id }
        let(:budget_parameter) { { _links: { costObject: { href: budget_link } } } }
        let(:params) { valid_params.merge(budget_parameter) }

        before do allow(User).to receive(:current).and_return current_user end

        context 'valid' do
          include_context 'patch request'

          it { expect(response.status).to eq(200) }

          it 'should respond with the work package and its new budget' do
            expect(subject.body).to be_json_eql(target_budget.subject.to_json)
              .at_path('_embedded/costObject/subject')
          end
        end

        context 'not valid' do
          let(:target_budget) { FactoryBot.create(:cost_object) }

          include_context 'patch request'

          it_behaves_like 'constraint violation' do
            let(:message) { I18n.t('activerecord.errors.messages.inclusion') }
          end
        end
      end
    end
  end
end
