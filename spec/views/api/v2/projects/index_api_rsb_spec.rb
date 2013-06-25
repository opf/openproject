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

describe '/api/v2/projects/index.api.rsb' do
  before do
    view.extend TimelinesHelper
  end

  before do
    params[:format] = 'xml'
  end

  describe 'with no project available' do
    it 'renders an empty projects document' do
      assign(:projects, [])

      render

      response.should have_selector('projects', :count => 1)
      response.should have_selector('projects[type=array][size="0"]') do
        without_tag 'project'
      end
    end
  end


  describe 'with some projects available' do
    let(:projects) {
      [
        FactoryGirl.build(:project, :name => 'P1'),
        FactoryGirl.build(:project, :name => 'P2'),
        FactoryGirl.build(:project, :name => 'P3')
      ]
    }

    it 'renders a projects document with the size of 3 of type array' do
      assign(:projects, projects)

      render

      response.should have_selector('projects', :count => 1)
      response.should have_selector('projects[type=array][size="3"]')
    end

    it 'renders a project for each assigned project' do
      assign(:projects, projects)

      render

      response.should have_selector('projects project', :count => 3)
    end

    it 'renders the _project template for each assigned project' do
      assign(:projects, projects)

      view.should_receive(:render).exactly(3).times.with(hash_including(:partial => '/api/v2/projects/project.api')).and_return('')

      # just to call the speced template despite the should receive expectations above
      view.should_receive(:render).once.with({ :template=>"/api/v2/projects/index", :handlers=>["rsb"], :formats=>["api"] }, {}).and_call_original

      render
    end

    it 'passes the projects as local var to the partial' do
      assign(:projects, projects)

      view.should_receive(:render).once.with(hash_including(:object => projects.first)).and_return('')
      view.should_receive(:render).once.with(hash_including(:object => projects.second)).and_return('')
      view.should_receive(:render).once.with(hash_including(:object => projects.third)).and_return('')

      # just to call the speced template despite the should receive expectations above
      view.should_receive(:render).once.with({ :template=>"/api/v2/projects/index", :handlers=>["rsb"], :formats=>["api"] }, {}).and_call_original

      render
    end
  end
end
