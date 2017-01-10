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

describe 'api/v2/planning_element_type_colors/show.api.rabl', type: :view do
  before do
    params[:format] = 'json'
  end

  describe 'with an assigned color' do
    let(:color) {
      FactoryGirl.build(:color,
                        id:       1,
                        name:     'Awesometastic color',
                        hexcode:  '#FFFFFF',
                        position: 10,

                        created_at: Time.parse('Thu Jan 06 12:35:00 +0100 2011'),
                        updated_at: Time.parse('Fri Jan 07 12:35:00 +0100 2011'))
    }

    before do
      assign(:color, color)
      render
    end

    subject { rendered }

    it 'renders a color document' do
      is_expected.to have_json_path('color')
    end

    it 'renders the detail information about the color' do
      expected_json = { name: 'Awesometastic color', hexcode: '#FFFFFF', position: 10 }.to_json

      is_expected.to be_json_eql(expected_json).at_path('color')
    end
  end
end
