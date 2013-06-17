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

describe 'api/v2/reported_project_statuses/index.api.rsb' do
  before do
    view.extend TimelinesHelper
  end

  before do
    params[:format] = 'xml'
  end

  describe 'with no reported_project_statuses available' do
    it 'renders an empty reported_project_statuses document' do
      assign(:reported_project_statuses, [])

      render

      response.should have_selector('reported_project_statuses', :count => 1)
      response.should have_selector('reported_project_statuses[type=array][size="0"]') do
        without_tag 'reported_project_status'
      end
    end
  end

  describe 'with 3 reported_project_statuses available' do
    let(:reported_project_statuses) do
      [
        FactoryGirl.build(:reported_project_status),
        FactoryGirl.build(:reported_project_status),
        FactoryGirl.build(:reported_project_status)
      ]

    end

    before do
      assign(:reported_project_statuses, reported_project_statuses )
    end

    it 'renders a reported_project_statuses document with the size 3 of array' do

      render

      response.should have_selector('reported_project_statuses', :count => 1)
      response.should have_selector('reported_project_statuses[type=array][size="3"]')
    end

    it 'renders a reported_project_status for each assigned reported_project_status' do

      render

      response.should have_selector('reported_project_statuses reported_project_status', :count => 3)
    end

    it 'renders the _reported_project_status template for each assigned reported_project_status' do

      view.should_receive(:render).exactly(3).times.with(hash_including(:partial => '/api/v2/reported_project_statuses/reported_project_status.api')).and_return('')

      # just to render the speced template despite the should receive expectations above
      view.should_receive(:render).once.with({:template=>"api/v2/reported_project_statuses/index", :handlers=>["rsb"], :formats=>["api"]}, {}).and_call_original

      render
    end

    it 'passes the reported_project_statuses as local var to the partial' do

      view.should_receive(:render).once.with(hash_including(:object => reported_project_statuses.first)).and_return('')
      view.should_receive(:render).once.with(hash_including(:object => reported_project_statuses.second)).and_return('')
      view.should_receive(:render).once.with(hash_including(:object => reported_project_statuses.third)).and_return('')

      # just to render the speced template despite the should receive expectations above
      view.should_receive(:render).once.with({:template=>"api/v2/reported_project_statuses/index", :handlers=>["rsb"], :formats=>["api"]}, {}).and_call_original

      render
    end
  end
end
