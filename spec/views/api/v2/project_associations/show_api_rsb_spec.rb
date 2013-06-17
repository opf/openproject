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

describe 'api/v2/project_associations/show.api.rsb' do
  before do
    view.extend TimelinesHelper
  end

  before do
    params[:format] = 'xml'
  end

  describe 'with an assigned project_association' do
    let(:project_association) { FactoryGirl.build(:project_association) }

    it 'renders a project_association document' do
      assign(:project_association, project_association)

      render

      response.should have_selector('project_association', :count => 1)
    end

    it 'renders the _project_association template once' do
      assign(:project_association, project_association)

      view.should_receive(:render).once.with(hash_including(:partial => '/api/v2/project_associations/project_association.api')).and_return('')

      # just to render the speced template despite the should receive expectations above
      view.should_receive(:render).once.with({:template=>"api/v2/project_associations/show", :handlers=>["rsb"], :formats=>["api"]}, {}).and_call_original

      render
    end

    it 'passes the project_association as local var to the partial' do
      assign(:project_association, project_association)

      view.should_receive(:render).once.with(hash_including(:object => project_association)).and_return('')

      # just to render the speced template despite the should receive expectations above
      view.should_receive(:render).once.with({:template=>"api/v2/project_associations/show", :handlers=>["rsb"], :formats=>["api"]}, {}).and_call_original

      render
    end
  end
end
