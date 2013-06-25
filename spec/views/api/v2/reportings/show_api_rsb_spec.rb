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

describe 'api/v2/reportings/show.api.rsb' do
  before do
    view.extend TimelinesHelper
  end

  before do
    params[:format] = 'xml'
  end

  describe 'with an assigned reporting' do
    let(:reporting) { FactoryGirl.build(:reporting) }

    it 'renders a reporting document' do
      assign(:reporting, reporting)

      render

      response.should have_selector('reporting', :count => 1)
    end

    it 'renders the _reporting template once' do
      assign(:reporting, reporting)

      view.should_receive(:render).once.with(hash_including(:partial => '/api/v2/reportings/reporting.api')).and_return('')

      # just to render the speced template despite the should receive expectations above
      view.should_receive(:render).once.with({:template=>"api/v2/reportings/show", :handlers=>["rsb"], :formats=>["api"]}, {}).and_call_original

      render
    end

    it 'passes the reporting as local var to the partial' do
      assign(:reporting, reporting)

      view.should_receive(:render).once.with(hash_including(:object => reporting)).and_return('')

      # just to render the speced template despite the should receive expectations above
      view.should_receive(:render).once.with({:template=>"api/v2/reportings/show", :handlers=>["rsb"], :formats=>["api"]}, {}).and_call_original

      render
    end
  end
end
