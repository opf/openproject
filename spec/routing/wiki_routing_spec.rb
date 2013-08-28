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

describe WikiController do
  describe "routing" do
    it 'should connect GET /projects/:project_id/wiki/new to wiki/new' do
      get('/projects/abc/wiki/new').should route_to(:controller => 'wiki',
                                                    :action => 'new',
                                                    :project_id => 'abc')
    end

    it 'should connect GET /projects/:project_id/wiki/:id/new to wiki/new_child' do
      get('/projects/abc/wiki/def/new').should route_to(:controller => 'wiki',
                                                        :action => 'new_child',
                                                        :project_id => 'abc',
                                                        :id => 'def')
    end

    it 'should connect POST /projects/:project_id/wiki/new to wiki/create' do
      post('/projects/abc/wiki/new').should route_to(:controller => 'wiki',
                                                     :action => 'create',
                                                     :project_id => 'abc')
    end

    it 'should connect POST /projects/:project_id/wiki/:id/preview to wiki/preview' do
      post('/projects/abc/wiki/def/preview').should route_to(:controller => 'wiki',
                                                             :action => 'preview',
                                                             :project_id => 'abc',
                                                             :id => 'def')
    end

    it 'should connect POST /projects/:project_id/wiki/preview to wiki/preview' do
      post('/projects/abc/wiki/preview').should route_to(:controller => 'wiki',
                                                         :action => 'preview',
                                                         :project_id => 'abc')
    end

    it do
      post('/projects/abc/wiki/abc_wiki?version=3').should
        route_to(controller: 'wiki',
                 action: 'show',
                 id: 'abc_wiki',
                 version: '3')
    end
  end
end
