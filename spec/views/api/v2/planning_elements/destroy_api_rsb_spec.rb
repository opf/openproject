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

describe 'api/v2/planning_elements/destroy.api.rsb' do
  before do
    view.extend TimelinesHelper
    view.extend PlanningElementsHelper
  end

  before do
    view.stub(:include_journals?).and_return(false)

    params[:format] = 'xml'
  end

  let(:planning_element) { FactoryGirl.build(:planning_element) }

  describe 'with an assigned planning element' do
    it 'renders a planning_element document' do
      assign(:planning_element, planning_element)

      render

      response.should have_selector('planning_element', :count => 1)
    end

    it 'calls the render_planning_element helper once' do
      assign(:planning_element, planning_element)

      view.should_receive(:render_planning_element).once.and_return('')

      render
    end

    it 'passes the planning element as local var to the helper' do
      assign(:planning_element, planning_element)

      view.should_receive(:render_planning_element).once.with(anything, planning_element).and_return('')

      render
    end
  end
end
