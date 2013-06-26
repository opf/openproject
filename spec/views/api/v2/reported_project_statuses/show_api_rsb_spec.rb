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

describe 'api/v2/reported_project_statuses/show.api.rsb' do
  before do
    view.extend TimelinesHelper
  end

  before do
    params[:format] = 'xml'
  end

  describe 'with an assigned reported_project_status' do
    let(:project_status) { FactoryGirl.build(:reported_project_status) }

    it 'renders a reported_project_status document' do
      assign(:reported_project_status, project_status)

      render

      response.should have_selector('reported_project_status', :count => 1)
    end

    it 'renders the _reported_project_status template once' do
      assign(:reported_project_status, project_status)

      view.should_receive(:render).once.with(hash_including(:partial => '/api/v2/reported_project_statuses/reported_project_status.api')).and_return('')

      # just to call the original render despite the should_receive expectation
      view.should_receive(:render).once.with({:template=>"api/v2/reported_project_statuses/show", :handlers=>["rsb"], :formats=>["api"]}, {}).and_call_original

      render
    end

    it 'passes the reported_project_status as local var to the partial' do
      assign(:reported_project_status, project_status)

      view.should_receive(:render).once.with(hash_including(:object => project_status)).and_return('')

      # just to call the original render despite the should_receive expectation
      view.should_receive(:render).once.with({:template=>"api/v2/reported_project_statuses/show", :handlers=>["rsb"], :formats=>["api"]}, {}).and_call_original

      render
    end
  end
end
