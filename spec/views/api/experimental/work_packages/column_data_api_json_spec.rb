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

describe 'api/experimental/work_packages/column_data.api.rabl', type: :view do
  before do
    params[:format] = 'json'

    assign(:columns_data, columns_data)
    render
  end

  subject { response.body }

  describe 'with no column data' do
    let(:columns_data) { [] }

    it { is_expected.to have_json_path('columns_data') }
    it { is_expected.to have_json_size(0).at_path('columns_data') }
  end

  describe 'with column data' do
    let(:columns_data) { [[{ id: 1, name: 'Dairy Queen' }, { id: 2, name: 'Baskin Robbins' }]] }

    it { is_expected.to have_json_path('columns_data') }
    it { is_expected.to have_json_type(Array).at_path('columns_data')       }
    it { is_expected.to have_json_type(Array).at_path('columns_data/0')     }
    it { is_expected.to have_json_type(Object).at_path('columns_data/0/0')  }
  end
end
