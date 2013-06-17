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

describe 'api/v2/project_types/index.api.rsb' do
  before do
    view.extend TimelinesHelper
  end

  before do
    params[:format] = 'xml'
  end

  describe 'with no project types available' do
    it 'renders an empty project types document' do
      assign(:project_types, [])

      render

      response.should have_selector('project_types', :count => 1)
      response.should have_selector('project_types[type=array][size="0"]') do
        without_tag 'project_type'
      end
    end
  end

  describe 'with 3 project types available' do
    let(:project_types) do
      [
        FactoryGirl.build(:project_type),
        FactoryGirl.build(:project_type),
        FactoryGirl.build(:project_type)
      ]
    end


    it 'renders a project_types document with the size 3 of type array' do
      assign(:project_types, project_types)

      render

      response.should have_selector('project_types', :count => 1)
      response.should have_selector('project_types[type=array][size="3"]')
    end

    it 'renders a project_type for each assigned project' do
      assign(:project_types, project_types)
      render

      response.should have_selector('project_types project_type', :count => 3)
    end

    it 'renders the _project_type template for each assigned project type' do
      assign(:project_types, project_types)

      view.should_receive(:render).exactly(3).times.with(hash_including(:partial => '/api/v2/project_types/project_type.api')).and_return('')

      # just to call the original render method
      view.should_receive(:render).once.with({:template=>"api/v2/project_types/index", :handlers=>["rsb"], :formats=>["api"]}, {}).and_call_original

      render
    end

    it 'passes the project types as local var to the partial' do
      assign(:project_types, project_types)

      view.should_receive(:render).once.with(hash_including(:object => project_types.first)).and_return('')
      view.should_receive(:render).once.with(hash_including(:object => project_types.second)).and_return('')
      view.should_receive(:render).once.with(hash_including(:object => project_types.third)).and_return('')

      # just to call the original render method
      view.should_receive(:render).once.with({:template=>"api/v2/project_types/index", :handlers=>["rsb"], :formats=>["api"]}, {}).and_call_original

      render
    end
  end
end
