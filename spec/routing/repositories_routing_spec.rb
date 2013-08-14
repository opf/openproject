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

describe RepositoriesController do

  #TODO: the  repositories routes and routing specs should be fixed -> in Rails3, they dont work as before in Rails2
  #e.g. wildcard matchers are not passed as an array anymore

  describe "show" do
    it{ get("/projects/testproject/repository").should route_to( :controller => 'repositories', :action => 'show', :id => 'testproject' )}
  end

  describe "edit" do
    it {  get("/projects/testproject/repository/edit").should route_to( :controller => 'repositories', :action => 'edit', :id => 'testproject')}
    it { post("/projects/testproject/repository/edit").should route_to( :controller => 'repositories', :action => 'edit', :id => 'testproject')}
  end

  describe "revisions" do
    it { get("/projects/testproject/repository/revisions").should      route_to( :controller => 'repositories', :action => 'revisions', :id => 'testproject')}
    it { get("/projects/testproject/repository/revisions.atom").should route_to( :controller => 'repositories', :action => 'revisions', :id => 'testproject', :format => 'atom')}
    it { get("/projects/testproject/repository/revisions/2457").should route_to( :controller => 'repositories', :action => 'revision', :id => 'testproject', :rev => '2457')}
  end

  pending describe "diff" do
    it { get("/projects/testproject/repository/revisions/2457/diff").should             route_to( :controller => 'repositories', :action => 'diff', :id => 'testproject', :rev => '2457')}
    it { get("/projects/testproject/repository/revisions/2457/diff.diff").should        route_to( :controller => 'repositories', :action => 'diff', :id => 'testproject', :rev => '2457', :format => 'diff')}
    it { get("/projects/testproject/repository/diff/path/to/file.c").should             route_to( :controller => 'repositories', :action => 'diff', :id => 'testproject', :path => %w[path to file.c])}
    it { get("/projects/testproject/repository/revisions/2/diff/path/to/file.c").should route_to( :controller => 'repositories', :action => 'diff', :id => 'testproject', :path => %w[path to file.c], :rev => '2')}
  end

  pending describe "browse" do
    it { get("/projects/testproject/repository/browse/path/to/file.c").should route_to( :controller => 'repositories', :action => 'browse', :id => 'testproject', :path => %w[path to file.c])}
  end

  pending describe "entry" do
    it { get("/projects/testproject/repository/entry/path/to/file.c").should route_to( :controller => 'repositories', :action => 'entry', :id => 'testproject', :path => %w[path to file.c])}
    it { get("/projects/testproject/repository/revisions/2/entry/path/to/file.c").should route_to( :controller => 'repositories', :action => 'entry', :id => 'testproject', :path => %w[path to file.c], :rev => '2')}
    it { get("/projects/testproject/repository/raw/path/to/file.c").should route_to( :controller => 'repositories', :action => 'entry', :id => 'testproject', :path => %w[path to file.c], :format => 'raw')}
    it { get("/projects/testproject/repository/revisions/2/raw/path/to/file.c").should route_to( :controller => 'repositories', :action => 'entry', :id => 'testproject', :path => %w[path to file.c], :rev => '2', :format => 'raw')}
  end

  pending describe "annotate" do
    it { get("/projects/testproject/repository/annotate/path/to/file.c").should route_to( :controller => 'repositories', :action => 'annotate', :id => 'testproject', :path => %w[path to file.c])}
  end

  pending describe "changes" do
    it { get("/projects/testproject/repository/changes/path/to/file.c").should route_to( :controller => 'repositories', :action => 'changes', :id => 'testproject', :path => %w[path to file.c])}
  end

  describe "stats" do
    it { get("/projects/testproject/repository/statistics").should route_to( :controller => 'repositories', :action => 'stats', :id => 'testproject')}
  end

  describe "committers" do
    it { get("/projects/testproject/repository/committers").should route_to( :controller => 'repositories', :action => 'committers', :id => 'testproject')}
  end
end
