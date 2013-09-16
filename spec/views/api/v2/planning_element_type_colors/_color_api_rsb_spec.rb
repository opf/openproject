#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2013 the OpenProject Foundation (OPF)
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

describe 'api/v2/planning_element_type_colors/_color.api' do
  before do
    view.extend TimelinesHelper
  end

  # added to pass in locals
  def render
    params[:format] = 'xml'
    super(:partial => 'api/v2/planning_element_type_colors/color.api', :object => color)
  end

  describe 'with an assigned color' do
    let(:color) { FactoryGirl.build(:color,
                                :id       => 1,
                                :name     => 'Awesometastic color',
                                :hexcode  => '#FFFFFF',
                                :position => 10,

                                :created_at => Time.parse('Thu Jan 06 12:35:00 +0100 2011'),
                                :updated_at => Time.parse('Fri Jan 07 12:35:00 +0100 2011')) }

    it 'renders a color node' do
      render
      response.should have_selector('color', :count => 1)
    end

    describe 'color node' do
      it 'contains an id element containing the color id' do
        render
        response.should have_selector('color id', :text => '1')
      end

      it 'contains an name element containing the color name' do
        render
        response.should have_selector('color name', :text => 'Awesometastic color')
      end

      it 'contains a hexcode element containing the color hex code' do
        render
        response.should have_selector('color hexcode', :text => '#FFFFFF')
      end

      it 'contains an position element containing the color position' do
        render
        response.should have_selector('color position', :text => '10')
      end

      it 'contains a created_on element containing the color created_on in UTC in ISO 8601' do
        render
        response.should have_selector('color created_at', :text => '2011-01-06T11:35:00Z')
      end

      it 'contains an updated_on element containing the color updated_on in UTC in ISO 8601' do
        render
        response.should have_selector('color updated_at', :text => '2011-01-07T11:35:00Z')
      end
    end
  end
end
