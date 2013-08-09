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

describe ProjectsController do

  describe "index" do
    it { get("/projects").should      route_to( :controller => 'projects', :action => 'index')}
    it { get("/projects.atom").should route_to( :controller => 'projects', :action => 'index', :format => 'atom')}
    it { get("/projects.xml").should  route_to( :controller => 'projects', :action => 'index', :format => 'xml')}
  end


  describe "show" do
    it{ get("/projects/1").should       route_to( :controller => 'projects', :action => 'show', :id => '1' )}
    it{ get("/projects/1.xml").should   route_to( :controller => 'projects', :action => 'show', :id => '1', :format =>"xml")}
    it{ get("/projects/test").should    route_to( :controller => 'projects', :action => 'show', :id => 'test' )}
  end

  describe "new" do
    it { get("/projects/new").should route_to(:controller => 'projects', :action => 'new' )}

  end

  describe "create" do
    it { post("/projects").should     route_to( :controller => 'projects', :action => 'create')}
    it { post("/projects.xml").should route_to( :controller => 'projects', :action => 'create', :format => "xml")}
  end

  describe "update" do
    it { put("/projects/123").should      route_to(:controller => 'projects', :action => "update", :id => "123")}
    it { put("/projects/123.xml").should  route_to(:controller => 'projects', :action => "update", :id => "123", :format => "xml")}
  end

  describe "destroy_info" do
    it { get("/projects/123/destroy_info").should  route_to(:controller => 'projects', :action => "destroy_info", :id => "123")}
  end

  describe "delete" do
    it{ delete("/projects/123").should     route_to(:controller => 'projects', :action => "destroy", :id => "123")}
    it{ delete("/projects/123.xml").should route_to(:controller => 'projects', :action => "destroy", :id => "123", :format => "xml")}
  end

  describe "miscellanous" do
    it { get("/projects/123/settings").should         route_to(:controller => 'projects', :action =>"settings",   :id =>"123")}
    it { get("/projects/123/settings/members").should route_to(:controller => 'projects', :action =>"settings",   :id =>"123", :tab => "members")}
    it { put("projects/123/modules").should           route_to(:controller => 'projects', :action =>"modules",    :id =>"123")}
    it { put("projects/123/archive").should           route_to(:controller => 'projects', :action =>"archive",    :id =>"123")}
    it { put("projects/123/unarchive").should         route_to(:controller => 'projects', :action =>"unarchive",  :id =>"123")}
    it { get("projects/123/copy").should              route_to(:controller => 'projects', :action =>"copy",       :id =>"123")}
    it { post("projects/123/copy").should             route_to(:controller => 'projects', :action =>"copy",       :id =>"123")}
  end
end


