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

describe WorkPackagesController do

  it "should connect GET /work_packages/:id to work_packages#show" do
    get("/work_packages/1").should route_to( :controller => 'work_packages',
                                             :action => 'show',
                                             :id => '1' )
  end

  it "should connect GET /projects/:project_id/work_packages/new to work_packages#new" do
    get("/projects/1/work_packages/new").should route_to( :controller => 'work_packages',
                                                          :action => 'new',
                                                          :project_id => '1' )
  end

end
