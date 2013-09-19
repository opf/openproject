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

describe 'api/v2/planning_element_types/_planning_element_type.api' do
  before do
    view.extend TimelinesHelper
  end

  # added to pass in locals
  def render
    params[:format] = 'xml'
    super(:partial => 'api/v2/planning_element_types/planning_element_type.api', :object => planning_element_type)
  end

  describe 'with an assigned planning_element_type' do
    let(:planning_element_type) {
      FactoryGirl.build(:type,
                        :id => 1,
                        :name => 'Awesometastic Planning Element Type',

                        :in_aggregation => false,
                        :is_milestone => true,
                        :is_default => true,

                        :position => 100,

                        :created_at => Time.parse('Thu Jan 06 12:35:00 +0100 2011'),
                        :updated_at => Time.parse('Fri Jan 07 12:35:00 +0100 2011'))
    }

    it 'renders a planning_element_type node' do
      render

      response.should have_selector('planning_element_type', :count => 1)
    end

    describe 'planning_element_type node' do
      it 'contains an id element containing the planning element type id' do
        render

        response.should have_selector('planning_element_type id', :text => '1')
      end

      it 'contains a name element containing the planning element type name' do
        render

        response.should have_selector('planning_element_type name', :text => 'Awesometastic Planning Element Type')
      end

      it 'contains an in_aggregation element containing the planning element type field in_aggregation' do
        render

        response.should have_selector('planning_element_type in_aggregation', :text => 'false')
      end

      it 'contains an is_milestone element containing the planning element type field is_milestone' do
        render

        response.should have_selector('planning_element_type is_milestone', :text => 'true')
      end

      it 'contains an is_default element containing the planning element type field is_default' do
        render

        response.should have_selector('planning_element_type is_default', :text => 'true')
      end

      it 'contains an position element containing the planning element type position' do
        render

        response.should have_selector('planning_element_type position', :text => '100')
      end

      it 'does not contain a color element' do
        render

        response.should_not have_selector('planning_element_type color')
      end

      it 'contains a created_at element containing the planning element type created_at in UTC in ISO 8601' do
        render

        response.should have_selector('planning_element_type created_at', :text => '2011-01-06T11:35:00Z')
      end

      it 'contains an updated_at element containing the planning element type updated_at in UTC in ISO 8601' do
        render

        response.should have_selector('planning_element_type updated_at', :text => '2011-01-07T11:35:00Z')
      end
    end
  end

  describe 'with a planning element type having a color' do
    let(:color) { FactoryGirl.create(:color_white, :id => 1338) }

    let(:planning_element_type) { FactoryGirl.build(:type,
                                                    :color_id => color.id) }

    describe 'planning_element_type node' do
      it 'contains a color element with name, id and hexcode attributes' do
        render

        response.should have_selector('planning_element_type color[name=white][id="1338"][hexcode="#FFFFFF"]', :count => 1)
      end
    end
  end
end
