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

describe 'api/v2/scenarios/_scenario.api' do
  before do
    view.extend TimelinesHelper
  end

  # added to pass in locals
  def render
    params[:format] = 'xml'
    super(:partial => 'api/v2/scenarios/scenario.api', :object => scenario)
  end

  describe 'with an assigned scenario' do
    let(:project) { FactoryGirl.create(:project, :id => 4711,
                                             :identifier => 'test_project',
                                             :name => 'Test Project') }
    let(:scenario) { FactoryGirl.build(:scenario,
                                           :id => 1,
                                           :project_id => project.id,
                                           :name => 'Awesometastic scenario',
                                           :description => 'Description of this scenario',

                                           :created_at => Time.parse('Thu Jan 06 12:35:00 +0100 2011'),
                                           :updated_at => Time.parse('Fri Jan 07 12:35:00 +0100 2011')) }

    it 'renders a scenario node' do
      render
      response.should have_selector('scenario', :count => 1)
    end

    describe 'scenario node' do
      it 'contains an id element containing the scenario id' do
        render
        response.should have_selector('scenario id', :text => '1')
      end

      it 'contains a project element containing the scenario\'s project id, identifier and name' do
        render
        response.should have_selector('scenario project[id="4711"][identifier="test_project"][name="Test Project"]')
      end

      it 'contains an name element containing the scenario name' do
        render
        response.should have_selector('scenario name', :text => 'Awesometastic scenario')
      end

      it 'contains an description element containing the scenario description' do
        render
        response.should have_selector('scenario description', :text => 'Description of this scenario')
      end

      it 'contains a created_at element containing the scenario created_at in UTC in ISO 8601' do
        render
        response.should have_selector('scenario created_at', :text => '2011-01-06T11:35:00Z')
      end

      it 'contains an updated_at element containing the scenario updated_at in UTC in ISO 8601' do
        render
        response.should have_selector('scenario updated_at', :text => '2011-01-07T11:35:00Z')
      end
    end
  end
end
