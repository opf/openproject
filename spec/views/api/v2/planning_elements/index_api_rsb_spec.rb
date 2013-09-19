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

describe 'api/v2/planning_elements/index.api.rsb' do
  before do
    view.extend TimelinesHelper
    view.extend PlanningElementsHelper
  end

  before do
    view.stub(:include_journals?).and_return(false)

    params[:format] = 'xml'
  end

  describe 'with no planning elements available' do
    it 'renders an empty planning_elements document' do
      assign(:planning_elements, [])

      render

      response.should have_selector('planning_elements', :count => 1)
      response.should have_selector('planning_elements[type=array][size="0"]') do
        without_tag 'planning_element'
      end
    end
  end

  describe 'with 3 planning elements available' do
    let(:planning_elements) {
      [ FactoryGirl.build(:work_package),
        FactoryGirl.build(:work_package),
        FactoryGirl.build(:work_package)
      ]
    }

    it 'renders a planning_elements document with the size 3 of array' do
      assign(:planning_elements, planning_elements)

      render

      response.should have_selector('planning_elements', :count => 1)
      response.should have_selector('planning_elements[type=array][size="3"]')
    end

    it 'renders a planning_element for each assigned planning element' do
      assign(:planning_elements, planning_elements)

      render

      response.should have_selector('planning_elements planning_element', :count => 3)
    end

    it 'calls the render_planning_element helper for each assigned planning element' do
      assign(:planning_elements, planning_elements)

      view.should_receive(:render_planning_element).exactly(3).times

      render
    end

    it 'passes the planning elements as local var to the helper' do
      assign(:planning_elements, planning_elements)

      view.should_receive(:render_planning_element).once.with(anything, planning_elements.first).and_return('')
      view.should_receive(:render_planning_element).once.with(anything, planning_elements.second).and_return('')
      view.should_receive(:render_planning_element).once.with(anything, planning_elements.third).and_return('')

      render
    end
  end
end
