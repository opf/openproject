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

describe ::API::V3::Grids::GridRepresenter do
  include OpenProject::StaticRouting::UrlHelpers

  let(:current_user) { FactoryBot.build_stubbed(:user) }
  let(:representer) { described_class.new(OpenStruct.new, current_user: current_user) }

  context 'generation' do
    subject(:generated) { representer.to_json }

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

    it 'has a list of widgets' do
      widgets = [
        {
          "_type": "Widget",
          "startRow": '2',
          "endRow": '4',
          "startColumn": '2',
          "endColumn": '4'
        }
      ]

      is_expected
        .to be_json_eql(widgets.to_json)
        .at_path('widgets')
    end
  end
end
