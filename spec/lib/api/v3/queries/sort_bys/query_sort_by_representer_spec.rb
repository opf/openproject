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

describe ::API::V3::Queries::SortBys::QuerySortByRepresenter, clear_cache: true do
  include ::API::V3::Utilities::PathHelper

  let(:column_name) { 'status' }
  let(:direction) { 'desc' }
  let(:column) { Queries::WorkPackages::Columns::PropertyColumn.new(column_name) }
  let(:decorator) { ::API::V3::Queries::SortBys::SortByDecorator.new(column, direction) }
  let(:representer) do
    described_class
      .new(decorator)
  end

  subject { representer.to_json }

  describe 'generation' do
    describe '_links' do
      it_behaves_like 'has a titled link' do
        let(:link) { 'self' }
        let(:href) { api_v3_paths.query_sort_by 'status', 'desc' }
        let(:title) { 'Status (Descending)' }
      end
    end

    it 'has _type QuerySortBy' do
      is_expected
        .to be_json_eql('QuerySortBy'.to_json)
        .at_path('_type')
    end

    it 'has id attribute' do
      is_expected
        .to be_json_eql('status-desc'.to_json)
        .at_path('id')
    end

    it 'has name attribute' do
      is_expected
        .to be_json_eql('Status (Descending)'.to_json)
        .at_path('name')
    end

    it_behaves_like 'has a titled link' do
      let(:link) { 'column' }
      let(:href) { api_v3_paths.query_column 'status' }
      let(:title) { 'Status' }
    end

    it_behaves_like 'has a titled link' do
      let(:link) { 'direction' }
      let(:href) { "urn:openproject-org:api:v3:queries:directions:#{direction}" }
      let(:title) { 'Descending' }
    end

    context 'when providing an unsupported sort direction' do
      let(:direction) { 'bogus' }

      it 'raises error' do
        expect { subject }.to raise_error(ArgumentError)
      end
    end

    context 'when sorting differently' do
      let(:direction) { 'asc' }

      it 'has id attribute' do
        is_expected
          .to be_json_eql('status-asc'.to_json)
          .at_path('id')
      end

      it 'has name attribute' do
        is_expected
          .to be_json_eql('Status (Ascending)'.to_json)
          .at_path('name')
      end
    end

    context 'for a translated column' do
      let(:column_name) { 'assigned_to' }

      describe '_links' do
        it_behaves_like 'has a titled link' do
          let(:link) { 'self' }
          let(:href) { api_v3_paths.query_sort_by 'assignee', 'desc' }
          let(:title) { 'Assignee (Descending)' }
        end
      end

      it 'has id attribute' do
        is_expected
          .to be_json_eql('assignee-desc'.to_json)
          .at_path('id')
      end

      it 'has name attribute' do
        is_expected
          .to be_json_eql('Assignee (Descending)'.to_json)
          .at_path('name')
      end
    end
  end

  describe 'caching' do
    before do
      # fill the cache
      representer.to_json
    end

    it 'is cached' do
      expect(representer)
        .not_to receive(:to_hash)

      representer.to_json
    end

    it 'busts the cache on changes to the column_caption (cf rename)' do
      allow(decorator)
        .to receive(:column_caption)
        .and_return('blubs')

      expect(representer)
        .to receive(:to_hash)

      representer.to_json
    end

    it 'busts the cache on a different direction' do
      allow(decorator)
        .to receive(:direction_name)
        .and_return('asc')

      expect(representer)
        .to receive(:to_hash)

      representer.to_json
    end

    it 'busts the cache on changes to the locale' do
      expect(representer)
        .to receive(:to_hash)

      I18n.with_locale(:de) do
        representer.to_json
      end
    end
  end
end
