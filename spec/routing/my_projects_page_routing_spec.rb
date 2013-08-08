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

describe MyProjectsOverviewsController do
  describe "routing" do
    describe "overview-page" do
      it { get('/projects/test-project').should route_to(:controller => 'my_projects_overviews',
                                                         :action => 'index',
                                                         :id => 'test-project') }

      # make sure that the mappings are not greedy
      it { get('/projects/new').should route_to(:controller => 'projects',
                                                :action => 'new') }

      it { get('/projects/test-project/settings').should route_to(:controller => 'projects',
                                                                  :action => 'settings',
                                                                  :id => 'test-project') }

    end


  end
end
