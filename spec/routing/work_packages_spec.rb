#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2013 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe WorkPackagesController do

  it "should connect GET /work_packages to work_packages#index" do
    get("/work_packages").should route_to( :controller => 'work_packages',
                                           :action => 'index')
  end

  it "should connect GET /projects/blubs/work_packages to work_packages#index" do
    get("/projects/blubs/work_packages").should route_to( :controller => 'work_packages',
                                                          :project_id => 'blubs',
                                                          :action => 'index')
  end

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

  it "should connect GET /projects/:project_id/work_packages/new_type to work_packages#new_type" do
    get("/projects/1/work_packages/new_type").should route_to( :controller => 'work_packages',
                                                                  :action => 'new_type',
                                                                  :project_id => '1' )
  end

  it "should connect GET /work_packages/1/new_type to work_packages#new_type" do
    get("/work_packages/1/new_type").should route_to( :controller => 'work_packages',
                                                      :action => 'new_type',
                                                      :id => '1' )
  end

  it "should connect GET /work_packages/:id/edit to work_packages#edit" do
    get("/work_packages/1/edit").should route_to( :controller => 'work_packages',
                                                  :action => 'edit',
                                                  :id => '1' )
  end

  it "should connect POST /projects/:project_id/work_packages to work_packages#new" do
    post("/projects/1/work_packages").should route_to( :controller => 'work_packages',
                                                       :action => 'create',
                                                       :project_id => '1' )
  end

  it "should connect GET /work_packages/:work_package_id/moves/new to work_packages/moves#new" do
    get("/work_packages/1/move/new").should route_to( :controller => 'work_packages/moves',
                                                      :action => 'new',
                                                      :work_package_id => '1' )
  end

  it "should connect POST /work_packages/:work_package_id/moves to work_packages/moves#create" do
    post("/work_packages/1/move/").should route_to( :controller => 'work_packages/moves',
                                                    :action => 'create',
                                                    :work_package_id => '1' )
  end

  it "should connect GET /work_packages/moves/new?ids=1,2,3 to work_packages/moves#new" do
    get("/work_packages/move/new?ids=1,2,3").should route_to( :controller => 'work_packages/moves',
                                                              :action => 'new' )
  end

  it "should connect POST /work_packages/moves to work_packages/moves#create" do
    post("/work_packages/move?ids=1,2,3").should route_to( :controller => 'work_packages/moves',
                                                            :action => 'create' )
  end

  it "should connect PUT /work_packages/1 to work_packages#update" do
    put("/work_packages/1").should route_to( :controller => 'work_packages',
                                             :action => 'update',
                                             :id => '1' )
  end
end
