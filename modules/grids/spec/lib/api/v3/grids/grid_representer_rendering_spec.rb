#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2018 the OpenProject Foundation (OPF)
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

describe ::API::V3::Grids::GridRepresenter, 'rendering' do
  include OpenProject::StaticRouting::UrlHelpers

  let(:grid) do
    FactoryBot.build_stubbed(
      :my_page,
      row_count: 4,
      column_count: 5,
      widgets: [
        FactoryBot.build_stubbed(
          :grid_widget,
          identifier: 'work_packages_assigned',
          start_row: 4,
          end_row: 5,
          start_column: 1,
          end_column: 2
        ),
        FactoryBot.build_stubbed(
          :grid_widget,
          identifier: 'work_packages_created',
          start_row: 1,
          end_row: 2,
          start_column: 1,
          end_column: 2
        ),
        FactoryBot.build_stubbed(
          :grid_widget,
          identifier: 'work_packages_watched',
          start_row: 2,
          end_row: 4,
          start_column: 4,
          end_column: 5
        )
      ]
    )
  end

  let(:current_user) { FactoryBot.build_stubbed(:user) }
  let(:representer) { described_class.new(grid, current_user: current_user) }

  context 'generation' do
    subject(:generated) { representer.to_json }

    context 'properties' do
      it 'denotes its type' do
        is_expected
          .to be_json_eql('Grid'.to_json)
          .at_path('_type')
      end

      it 'identifies the url the grid is stored for' do
        is_expected
          .to be_json_eql(my_page_path.to_json)
          .at_path('_links/page/href')
      end

      it 'has an id' do
        is_expected
          .to be_json_eql(grid.id)
          .at_path('id')
      end

      it 'has a rowCount' do
        is_expected
          .to be_json_eql(4)
          .at_path('rowCount')
      end

      it 'has a columnCount' do
        is_expected
          .to be_json_eql(5)
          .at_path('columnCount')
      end

      describe 'createdAt' do
        it_behaves_like 'has UTC ISO 8601 date and time' do
          let(:date) { grid.created_at }
          let(:json_path) { 'createdAt' }
        end
      end

      describe 'updatedAt' do
        it_behaves_like 'has UTC ISO 8601 date and time' do
          let(:date) { grid.updated_at }
          let(:json_path) { 'updatedAt' }
        end
      end

      it 'has a list of widgets' do
        widgets = [
          {
            "_type": "GridWidget",
            "identifier": 'work_packages_assigned',
            "startRow": 4,
            "endRow": 5,
            "startColumn": 1,
            "endColumn": 2
          },
          {
            "_type": "GridWidget",
            "identifier": 'work_packages_created',
            "startRow": 1,
            "endRow": 2,
            "startColumn": 1,
            "endColumn": 2
          },
          {
            "_type": "GridWidget",
            "identifier": 'work_packages_watched',
            "startRow": 2,
            "endRow": 4,
            "startColumn": 4,
            "endColumn": 5
          }
        ]

        is_expected
          .to be_json_eql(widgets.to_json)
          .at_path('widgets')
      end
    end

    context '_links' do
      context 'self link' do
        it_behaves_like 'has an untitled link' do
          let(:link) { 'self' }
          let(:href) { "/api/v3/grids/#{grid.id}" }
        end
      end

      context 'update link' do
        it_behaves_like 'has an untitled link' do
          let(:link) { 'update' }
          let(:href) { "/api/v3/grids/#{grid.id}/form" }
          let(:method) { :post }
        end
      end

      context 'updateImmediately link' do
        it_behaves_like 'has an untitled link' do
          let(:link) { 'updateImmediately' }
          let(:href) { "/api/v3/grids/#{grid.id}" }
          let(:method) { :patch }
        end
      end

      context 'page link' do
        it_behaves_like 'has an untitled link' do
          let(:link) { 'page' }
          let(:href) { my_page_path }
          let(:type) { "text/html" }

          it 'has a content type of html' do
            is_expected
              .to be_json_eql(type.to_json)
              .at_path("_links/#{link}/type")
          end
        end
      end
    end
  end
end
