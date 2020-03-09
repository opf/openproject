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

describe 'API v3 Cost Entry resource' do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  let(:current_user) do
    FactoryBot.create(:user, member_in_project: project, member_through_role: role)
  end
  let(:role) { FactoryBot.create(:role, permissions: permissions) }
  let(:permissions) { [:view_cost_entries] }
  let(:project) { FactoryBot.create(:project) }
  subject(:response) { last_response }

  let(:cost_entry) { FactoryBot.create(:cost_entry, project: project) }

  before do
    login_as(current_user)

    get get_path
  end

  describe 'cost_entries/:id' do
    let(:get_path) { api_v3_paths.cost_entry cost_entry.id }

    context 'user can see cost entries' do
      context 'valid id' do
        it 'should return HTTP 200' do
          expect(response.status).to eql(200)
        end
      end

      context 'invalid id' do
        let(:get_path) { api_v3_paths.cost_type 'bogus' }

        it_behaves_like 'param validation error' do
          let(:id) { 'bogus' }
        end
      end
    end

    context 'user can only see own cost entries' do
      let(:permissions) { [:view_own_cost_entries] }

      context 'cost entry is not his own' do
        it_behaves_like 'error response',
                        403,
                        'MissingPermission',
                        I18n.t('api_v3.errors.code_403')
      end

      context 'cost entry is his own' do
        let(:cost_entry) { FactoryBot.create(:cost_entry, project: project, user: current_user) }

        it 'should return HTTP 200' do
          expect(response.status).to eql(200)
        end
      end
    end

    context 'user has no cost entry permissions' do
      let(:permissions) { [] }

      describe 'he can\'t even see own cost entries' do
        let(:cost_entry) { FactoryBot.create(:cost_entry, project: project, user: current_user) }
        it_behaves_like 'error response',
                        403,
                        'MissingPermission',
                        I18n.t('api_v3.errors.code_403')
      end
    end
  end
end
