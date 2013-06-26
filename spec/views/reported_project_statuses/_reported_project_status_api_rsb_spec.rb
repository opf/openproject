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

require File.expand_path('../../../spec_helper', __FILE__)

describe 'api/v2/reported_project_statuses/_reported_project_status.api' do
  before do
    view.extend TimelinesHelper
  end

  # added to pass in locals
  def render
    params[:format] = 'xml'
    super(:partial => 'api/v2/reported_project_statuses/reported_project_status.api', :object => reported_project_status)
  end

  describe 'with an assigned reported_project_status' do
    let(:reported_project_status) { FactoryGirl.build(:reported_project_status,
                                                      :id         => 1,
                                                      :name       => 'Awesometastic reported_project_status',
                                                      :is_default => true,
                                                      :position   => 10) }

    it 'renders a reported_project_status node' do
      render
      response.should have_selector('reported_project_status', :count => 1)
    end

    describe 'reported_project_status node' do
      it 'contains an id element containing the reported_project_status id' do
        render
        response.should have_selector('reported_project_status id', :text => '1')
      end

      it 'contains a name element containing the reported_project_status name' do
        render
        response.should have_selector('reported_project_status name', :text => 'Awesometastic reported_project_status')
      end

      it 'contains a position element containing the reported_project_status position' do
        render
        response.should have_selector('reported_project_status position', :text => '10')
      end

      it 'contains a is_default element containing the reported_project_status is_default property' do
        render
        response.should have_selector('reported_project_status is_default', :text => 'true')
      end
    end
  end
end
