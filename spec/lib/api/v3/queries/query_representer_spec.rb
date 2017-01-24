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

describe ::API::V3::Queries::QueryRepresenter do
  include ::API::V3::Utilities::PathHelper

  let(:query) { FactoryGirl.build_stubbed(:query, project: project) }
  let(:project) { FactoryGirl.build_stubbed(:project) }
  let(:representer) { described_class.new(query, current_user: double('current_user')) }

  subject { representer.to_json }

  describe 'generation' do
    describe '_links' do
      it_behaves_like 'has a titled link' do
        let(:link) { 'self' }
        let(:href) { api_v3_paths.query query.id }
        let(:title) { query.name }
      end

      it_behaves_like 'has a titled link' do
        let(:link) { 'user' }
        let(:href) { api_v3_paths.user query.user_id }
        let(:title) { query.user.name }
      end

      it_behaves_like 'has a titled link' do
        let(:link) { 'project' }
        let(:href) { api_v3_paths.project query.project_id }
        let(:title) { query.project.name }
      end

      it_behaves_like 'has an untitled link' do
        let(:link) { 'results' }
        let(:href) do
          params = {
            offset: 1,
            pageSize: Setting.per_page_options_array.first
          }
          "#{api_v3_paths.work_packages_by_project(project.id)}?#{params.to_query}"
        end
      end

      context 'has no project' do
        let(:query) { FactoryGirl.build_stubbed(:query, project: nil) }

        it_behaves_like 'has an empty link' do
          let(:link) { 'project' }
        end

        it_behaves_like 'has an untitled link' do
          let(:link) { 'results' }
          let(:href) do
            params = {
              offset: 1,
              pageSize: Setting.per_page_options_array.first
            }
            "#{api_v3_paths.work_packages}?#{params.to_query}"
          end
        end
      end

      context 'with filter, sort, group by and pageSize' do
        let(:representer) do
          described_class.new(query,
                              current_user: double('current_user'))
        end

        let(:query) do
          query = FactoryGirl.build_stubbed(:query, project: project)
          query.add_filter('subject', '~', ['bogus'])
          query.group_by = 'author'
          query.sort_criteria = [['assigned_to_id', 'asc'], ['type_id', 'desc']]

          query
        end

        let(:expected_href) do
          params = {
            offset: 1,
            pageSize: Setting.per_page_options_array.first,
            filters: JSON::dump([{ subject: { operator: '~', values: ['bogus'] } }]),
            groupBy: 'author',
            sortBy: JSON::dump([['assignee', 'asc'], ['type', 'desc']])
          }

          api_v3_paths.work_packages_by_project(project.id) + "?#{params.to_query}"
        end

        it_behaves_like 'has an untitled link' do
          let(:link) { 'results' }
          let(:href) { expected_href }
        end
      end

      context 'with offset and page size' do
        let(:representer) do
          described_class.new(query,
                              current_user: double('current_user'),
                              params: { offset: 2, pageSize: 25 })
        end

        let(:expected_href) do
          params = {
            offset: 2,
            pageSize: 25
          }

          api_v3_paths.work_packages_by_project(project.id) + "?#{params.to_query}"
        end

        it_behaves_like 'has an untitled link' do
          let(:link) { 'results' }
          let(:href) { expected_href }
        end
      end
    end

    it 'should show an id' do
      is_expected.to be_json_eql(query.id).at_path('id')
    end

    it 'should show the query name' do
      is_expected.to be_json_eql(query.name.to_json).at_path('name')
    end

    it 'should indicate whether sums are shown' do
      is_expected.to be_json_eql(query.display_sums.to_json).at_path('displaySums')
    end

    it 'should indicate whether the query is publicly visible' do
      is_expected.to be_json_eql(query.is_public.to_json).at_path('isPublic')
    end

    describe 'grouping' do
      let(:query) { FactoryGirl.build_stubbed(:query, group_by: 'assigned_to') }

      it 'should show the grouping column' do
        is_expected.to be_json_eql('assignee'.to_json).at_path('groupBy')
      end

      context 'without grouping' do
        let(:query) { FactoryGirl.build_stubbed(:query, group_by: nil) }

        it 'should show no grouping column' do
          is_expected.to be_json_eql(nil.to_json).at_path('groupBy')
        end
      end
    end

    describe 'with filters' do
      let(:query) do
        query = FactoryGirl.build_stubbed(:query)
        query.add_filter('status_id', '=', ['1'])
        query
      end

      it 'should render the filters' do
        expected = [
          {
            status: {
              operator: '=',
              values: ['1']
            }
          }
        ]
        is_expected.to be_json_eql(expected.to_json).at_path('filters')
      end
    end

    describe 'with sort criteria' do
      let(:query) do
        FactoryGirl.build_stubbed(:query,
                                  sort_criteria: [['subject', 'asc'], ['assigned_to', 'desc']])
      end

      it 'should render the filters' do
        is_expected
          .to be_json_eql([['subject', 'asc'], ['assignee', 'desc']].to_json)
          .at_path('sortCriteria')
      end
    end

    describe 'with columns' do
      let(:query) { FactoryGirl.build_stubbed(:query, column_names: ['subject', 'assigned_to']) }

      it 'should render the filters' do
        is_expected.to be_json_eql(['subject', 'assignee'].to_json).at_path('columnNames')
      end
    end

    describe 'embedded results' do
      let(:query) { FactoryGirl.build_stubbed(:query) }
      let(:representer) do
        described_class.new(query,
                            current_user: double('current_user'),
                            results: results_representer)
      end

      context 'results are provided' do
        let(:results_representer) do
          {
            _type: 'BogusResultType'
          }
        end

        it 'should embed the results' do
          is_expected
            .to be_json_eql('BogusResultType'.to_json)
            .at_path('_embedded/results/_type')
        end
      end

      context 'no results provided' do
        let(:results_representer) { nil }

        it 'should not embed the results' do
          is_expected
            .not_to have_json_path('_embedded/results')
        end
      end
    end
  end
end
