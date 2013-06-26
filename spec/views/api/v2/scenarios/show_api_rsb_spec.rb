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

describe 'api/v2/scenarios/show.api.rsb' do
  before do
    view.extend TimelinesHelper
  end

  before do
    params[:format] = 'xml'
  end

  describe 'with an assigned scenario' do
    let(:scenario) { FactoryGirl.build(:scenario) }

    before do
      assign(:scenario, scenario)
    end

    it 'renders a scenario document' do

      render

      response.should have_selector('scenario', :count => 1)
    end

    it 'renders the _scenario template once' do
      view.should_receive(:render).once.with(hash_including(:partial => '/api/v2/scenarios/scenario.api')).and_return('')

      # just to render the speced template despite the should receive expectations above
      view.should_receive(:render).once.with({:template=>"api/v2/scenarios/show", :handlers=>["rsb"], :formats=>["api"]}, {}).and_call_original

      render
    end

    it 'passes the scenario as local var to the partial' do

      view.should_receive(:render).once.with(hash_including(:object => scenario)).and_return('')

      # just to render the speced template despite the should receive expectations above
      view.should_receive(:render).once.with({:template=>"api/v2/scenarios/show", :handlers=>["rsb"], :formats=>["api"]}, {}).and_call_original

      render
    end
  end
end
