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

require 'spec_helper'


describe 'repositories/stats' do
  let(:project) { FactoryGirl.create(:project) }

  before do
    assign(:project, project)
  end

  describe 'requested by a user with view_commit_author_statistics permission' do
    before do
      assign(:show_commits_per_author, true)
      render
    end

    it 'should embed the commits per author graph' do
      response.body.should include('commits_per_author')
    end
  end

  describe 'requested by a user without view_commit_author_statistics permission' do
    before do
      assign(:show_commits_per_author, false)
      render
    end

    it 'should NOT embed the commits per author graph' do
      response.body.should_not include('commits_per_author')
    end
  end
end
