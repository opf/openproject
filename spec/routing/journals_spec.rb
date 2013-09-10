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

describe JournalsController do
  it "should connect GET /journals/:id/edit to journals#edit" do
    get("/journals/1/edit").should route_to( :controller => 'journals',
                                             :action => 'edit',
                                             :id => '1' )
  end

  it "should connect PUT /journals/:id to journals#update" do
    put("/journals/1").should route_to( :controller => 'journals',
                                        :action => 'update',
                                        :id => '1' )
  end

  it "should connect GET /journals/:id/preview to journals#preview" do
    get("/journals/1/preview").should route_to( :controller => 'journals',
                                                :action => 'preview',
                                                :id => '1' )
  end
end
