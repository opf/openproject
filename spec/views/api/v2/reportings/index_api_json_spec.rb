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

describe 'api/v2/reportings/index.api.rabl', type: :view do
  before do
    params[:format] = 'json'
  end

  describe 'with no reportings available' do
    it 'renders an empty reportings document' do
      assign(:reportings, [])
      render
      expect(rendered).to have_json_size(0).at_path 'reportings'
    end
  end

  describe 'with 3 reportings available' do
    let(:reportings) do
      [
        FactoryGirl.build(:reporting),
        FactoryGirl.build(:reporting),
        FactoryGirl.build(:reporting)
      ]
    end

    it 'renders a reportings document with the size 3 of array' do
      assign(:reportings, reportings)

      render

      expect(rendered).to have_json_size(3).at_path 'reportings'
    end
  end
end
