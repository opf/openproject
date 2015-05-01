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

require File.expand_path('../../../../../spec_helper', __FILE__)

describe 'api/experimental/queries/available_columns.api.rabl', type: :view do
  before do
    params[:format] = 'json'

    assign(:available_columns, available_columns)
    render
  end

  subject { response.body }

  describe 'with no available columns' do
    let(:available_columns) { [] }

    it { is_expected.to have_json_path('available_columns') }
    it { is_expected.to have_json_size(0).at_path('available_columns') }
  end

  describe 'with 2 available columns' do
    let(:available_columns) {
      [
        {
          name:     'project',
          title:    'Project',
          sortable: 'projects.name',
          groupable: 'project',
          custom_field: false,
          meta_data: {
            data_type: 'object',
            link: {
              display:    true,
              model_type: 'project'
            }
          }
        }, {
          name:     'status',
          title:    'Status',
          sortable: 'statuses.name',
          groupable: 'status',
          custom_field: false,
          meta_data: {
            data_type: 'object',
            link: {
              display:    false,
              model_type: 'project'
            }
          }
        }
      ]
    }

    it { is_expected.to have_json_path('available_columns') }
    it { is_expected.to have_json_size(2).at_path('available_columns') }

    it { is_expected.to have_json_type(FalseClass).at_path('available_columns/1/custom_field') }
    it { is_expected.to have_json_type(Object).at_path('available_columns/1/meta_data') }
    it { is_expected.to have_json_type(String).at_path('available_columns/1/meta_data/link/model_type') }
  end

end
