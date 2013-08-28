#-- copyright
# OpenProject is a project management system.
#
# Copyright (C) 2012-2013 the OpenProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
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
      [ FactoryGirl.build(:planning_element),
        FactoryGirl.build(:planning_element),
        FactoryGirl.build(:planning_element)
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
