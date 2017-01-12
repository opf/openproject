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

describe 'API v3 Status resource' do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  let(:role) { FactoryGirl.create(:role, permissions: [:view_work_packages]) }
  let(:project) { FactoryGirl.create(:project, is_public: false) }
  let(:current_user) do
    FactoryGirl.create(:user,
                       member_in_project: project,
                       member_through_role: role)
  end

  let!(:statuses) { FactoryGirl.create_list(:status, 4) }

  describe 'statuses' do
    describe '#get' do
      let(:get_path) { api_v3_paths.statuses }
      subject(:response) { last_response }

      context 'logged in user' do
        before do
          allow(User).to receive(:current).and_return current_user

          get get_path
        end

        it_behaves_like 'API V3 collection response', 4, 4, 'Status'
      end

      context 'not logged in user' do
        before do
          get get_path
        end

        it_behaves_like 'error response',
                        403,
                        'MissingPermission',
                        I18n.t('api_v3.errors.code_403')
      end
    end
  end

  describe 'statuses/:id' do
    describe '#get' do
      let(:status) { statuses.first }
      let(:get_path) { api_v3_paths.status status.id }

      subject(:response) { last_response }

      context 'logged in user' do
        before do
          allow(User).to receive(:current).and_return(current_user)

          get get_path
        end

        context 'valid status id' do
          it { expect(response.status).to eq(200) }
        end

        context 'invalid status id' do
          let(:get_path) { api_v3_paths.status 'bogus' }

          it_behaves_like 'not found' do
            let(:id) { 'bogus' }
            let(:type) { 'Status' }
          end
        end
      end

      context 'not logged in user' do
        before do
          get get_path
        end

        it_behaves_like 'error response',
                        403,
                        'MissingPermission',
                        I18n.t('api_v3.errors.code_403')
      end
    end
  end
end
