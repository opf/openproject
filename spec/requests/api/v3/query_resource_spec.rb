#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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

describe 'API v3 Query resource', type: :request do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  let(:project) { FactoryGirl.create(:project, identifier: 'test_project', is_public: false) }
  let(:current_user) {
    FactoryGirl.create(:user, member_in_project: project, member_through_role: role)
  }
  let(:role) { FactoryGirl.create(:role, permissions: permissions) }
  let(:permissions) { [:view_work_packages] }
  let(:manage_public_queries_role) { FactoryGirl.create(:role, permissions: [:manage_public_queries]) }
  let(:query) { FactoryGirl.create(:public_query, project: project) }

  before do
    allow(User).to receive(:current).and_return current_user
  end

  describe '#get' do
    before do
      get api_v3_paths.query(query.id)
    end

    it 'should succeed' do
      expect(last_response.status).to eq(200)
    end

    context 'user not allowed to see queries' do
      let(:permissions) { [] }

      it_behaves_like 'not found'
    end
  end

  describe '#star' do
    let(:star_path) { api_v3_paths.query_star query.id }
    let(:filters) do
      query.filters.map { |f| { f.field.to_s => { 'operator' => f.operator, 'values' => f.values } } }
    end

    before(:each) do
      patch star_path
    end

    describe 'public queries' do
      context 'user with permission to manage public queries' do
        let(:permissions) { [:view_work_packages, :manage_public_queries] }

        context 'when starring an unstarred query' do
          it 'should respond with 200' do
            expect(last_response.status).to eq(200)
          end

          it 'should return the query with "isStarred" property set to true' do
            expect(last_response.body).to be_json_eql(true).at_path('isStarred')
          end
        end

        context 'when starring already starred query' do
          it 'should respond with 200' do
            expect(last_response.status).to eq(200)
          end

          it 'should return the query with "isStarred" property set to true' do
            expect(last_response.body).to be_json_eql(true).at_path('isStarred')
          end
        end

        context 'when trying to star nonexistent query' do
          let(:star_path) { api_v3_paths.query_star 999 }

          it_behaves_like 'not found' do
            let(:id) { 999 }
            let(:type) { 'Query' }
          end
        end
      end

      context 'user without permission to manage public queries' do
        let(:permissions) { [:view_work_packages] }

        it_behaves_like 'unauthorized access'
      end
    end

    describe 'private queries' do
      context 'user with permission to save queries' do
        let(:query) { FactoryGirl.create(:private_query, project: project, user: current_user) }
        let(:permissions) { [:view_work_packages, :save_queries] }

        context 'starring his own query' do
          it 'should respond with 200' do
            expect(last_response.status).to eq(200)
          end

          it 'should return the query with "isStarred" property set to true' do
            expect(last_response.body).to be_json_eql(true).at_path('isStarred')
          end
        end

        context 'trying to star somebody else\'s query' do
          let(:another_user) { FactoryGirl.create(:user) }
          let(:query) { FactoryGirl.create(:private_query, project: project, user: another_user) }

          it_behaves_like 'not found'
        end
      end

      context 'user without permission to save queries' do
        let(:query) { FactoryGirl.create(:private_query, project: project, user: current_user) }
        let(:permissions) { [:view_work_packages] }

        it_behaves_like 'unauthorized access'
      end
    end
  end

  describe '#unstar' do
    let(:unstar_path) { api_v3_paths.query_unstar query.id }
    let(:filters) do
      query.filters.map { |f| { f.field.to_s => { 'operator' => f.operator, 'values' => f.values } } }
    end

    describe 'public queries' do
      let(:query) { FactoryGirl.create(:public_query, project: project) }

      context 'user with permission to manage public queries' do
        let(:permissions) { [:view_work_packages, :manage_public_queries] }

        context 'when unstarring a starred query' do
          before(:each) do
            FactoryGirl.create(:query_menu_item, query: query)
            patch unstar_path
          end

          it 'should respond with 200' do
            expect(last_response.status).to eq(200)
          end

          it 'should return the query with "isStarred" property set to false' do
            expect(last_response.body).to be_json_eql(false).at_path('isStarred')
          end
        end

        context 'when unstarring an unstarred query' do
          before(:each) do patch unstar_path end

          it 'should respond with 200' do
            expect(last_response.status).to eq(200)
          end

          it 'should return the query with "isStarred" property set to true' do
            expect(last_response.body).to be_json_eql(false).at_path('isStarred')
          end
        end

        context 'when trying to unstar nonexistent query' do
          let(:unstar_path) { api_v3_paths.query_unstar 999 }
          before(:each) do patch unstar_path end

          it_behaves_like 'not found' do
            let(:id) { 999 }
            let(:type) { 'Query' }
          end
        end
      end

      context 'user without permission to manage public queries' do
        let(:permissions) { [:view_work_packages] }
        before(:each) do
          patch unstar_path
        end

        it_behaves_like 'unauthorized access'
      end
    end

    describe 'private queries' do
      context 'user with permission to save queries' do
        let(:query) { FactoryGirl.create(:private_query, project: project, user: current_user) }
        let(:permissions) { [:view_work_packages, :save_queries] }
        before(:each) do
          patch unstar_path
        end

        context 'unstarring his own query' do
          it 'should respond with 200' do
            expect(last_response.status).to eq(200)
          end

          it 'should return the query with "isStarred" property set to true' do
            expect(last_response.body).to be_json_eql(false).at_path('isStarred')
          end
        end

        context 'trying to unstar somebody else\'s query' do
          let(:another_user) { FactoryGirl.create(:user) }
          let(:query) { FactoryGirl.create(:private_query, project: project, user: another_user) }

          it_behaves_like 'not found'
        end
      end

      context 'user without permission to save queries' do
        let(:query) { FactoryGirl.create(:private_query, project: project, user: current_user) }
        let(:permissions) { [:view_work_packages] }
        before(:each) do
          patch unstar_path
        end

        it_behaves_like 'unauthorized access'
      end
    end
  end
end
