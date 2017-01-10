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

describe 'API v3 Category resource' do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  let(:role) { FactoryGirl.create(:role, permissions: []) }
  let(:private_project) { FactoryGirl.create(:project, is_public: false) }
  let(:public_project) { FactoryGirl.create(:project, is_public: true) }
  let(:anonymous_user) { FactoryGirl.create(:user) }
  let(:privileged_user) do
    FactoryGirl.create(:user,
                       member_in_project: private_project,
                       member_through_role: role)
  end

  let!(:categories) { FactoryGirl.create_list(:category, 3, project: private_project) }
  let!(:other_categories) { FactoryGirl.create_list(:category, 2, project: public_project) }
  let!(:user_categories) do
    FactoryGirl.create_list(:category,
                            2,
                            project: private_project,
                            assigned_to: privileged_user)
  end

  describe 'categories by project' do
    subject(:response) { last_response }

    context 'logged in user' do
      let(:get_path) { api_v3_paths.categories private_project.id }
      before do
        allow(User).to receive(:current).and_return privileged_user

        get get_path
      end

      it_behaves_like 'API V3 collection response', 5, 5, 'Category'
    end

    context 'not logged in user' do
      let(:get_path) { api_v3_paths.categories private_project.id }
      before do
        allow(User).to receive(:current).and_return anonymous_user

        get get_path
      end

      it_behaves_like 'not found' do
        let(:id) { private_project.id.to_s }
        let(:type) { 'Project' }
      end
    end
  end

  describe 'categories/:id' do
    subject(:response) { last_response }

    context 'logged in user' do
      let(:get_path) { api_v3_paths.category categories.first.id }
      before do
        allow(User).to receive(:current).and_return privileged_user

        get get_path
      end

      context 'valid priority id' do
        it 'should return HTTP 200' do
          expect(response.status).to eql(200)
        end
      end

      context 'invalid priority id' do
        let(:get_path) { api_v3_paths.category 'bogus' }
        it_behaves_like 'not found' do
          let(:id) { 'bogus' }
          let(:type) { 'Category' }
        end
      end
    end

    context 'not logged in user' do
      let(:get_path) { api_v3_paths.category 'bogus' }
      before do
        allow(User).to receive(:current).and_return anonymous_user

        get get_path
      end

      it_behaves_like 'not found' do
        let(:id) { 'bogus' }
        let(:type) { 'Category' }
      end
    end
  end
end
