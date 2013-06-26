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

describe 'api/v2/planning_element_type_colors/show.api.rsb' do
  before do
    view.extend TimelinesHelper
  end

  before do
    params[:format] = 'xml'
  end

  describe 'with an assigned color' do
    let(:color) { FactoryGirl.build(:color) }

    it 'renders a color document' do
      assign(:color, color)

      render

      response.should have_selector('color', :count => 1)
    end

    it 'renders the _color template once' do
      assign(:color, color)

      view.should_receive(:render).once.with(hash_including(:partial => '/api/v2/planning_element_type_colors/color.api')).and_return('')

      # in order to enable calling the original render method
      # despite should_receive expectations
      view.should_receive(:render).once.with(hash_including(:template => "api/v2/planning_element_type_colors/show"), {})
                                  .and_call_original

      render
    end

    it 'passes the color as local var to the partial' do
      assign(:color, color)

      view.should_receive(:render).once.with(hash_including(:object => color)).and_return('')

      # in order to enable calling the original render method
      # despite should_receive expectations
      view.should_receive(:render).once.with(hash_including(:template => "api/v2/planning_element_type_colors/show"), {})
                                  .and_call_original

      render
    end
  end
end
