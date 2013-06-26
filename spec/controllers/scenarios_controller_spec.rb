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

require File.expand_path('../../spec_helper', __FILE__)

describe ScenariosController do

  describe 'new.html' do
    let(:project)  { FactoryGirl.create(:project, :is_public  => false) }

    def fetch
      get 'new', :project_id => project.id
    end
    let(:permission) { :edit_project }
    it_should_behave_like "a controller action which needs project permissions"
  end

  describe 'create.html' do
    let(:project)  { FactoryGirl.create(:project, :is_public  => false) }

    def fetch
      post 'create', :project_id => project.id,
                     :scenario => FactoryGirl.build(:scenario,
                                                :project_id => project.id).attributes
    end
    let(:permission) { :edit_project }
    def expect_redirect_to
      project_settings_path(project)
    end
    it_should_behave_like "a controller action which needs project permissions"
  end

  describe 'edit.html' do
    let(:project)  { FactoryGirl.create(:project, :is_public  => false) }
    let(:scenario) { FactoryGirl.create(:scenario, :project_id => project.id) }

    def fetch
      get 'edit', :project_id => project.id, :id => scenario.id
    end
    let(:permission) { :edit_project }
    it_should_behave_like "a controller action which needs project permissions"
  end

  describe 'update.html' do
    let(:project)  { FactoryGirl.create(:project, :is_public  => false) }
    let(:scenario) { FactoryGirl.create(:scenario, :project_id => project.id) }

    def fetch
      post 'update', :project_id => project.id, :id => scenario.id, :scenario => { "name" => "blubs" }
    end
    let(:permission) { :edit_project }
    def expect_redirect_to
      project_settings_path(project)
    end
    it_should_behave_like "a controller action which needs project permissions"
  end

  describe 'confirm_destroy.html' do
    let(:project)  { FactoryGirl.create(:project, :is_public  => false) }
    let(:scenario) { FactoryGirl.create(:scenario, :project_id => project.id) }

    def fetch
      get 'confirm_destroy', :project_id => project.id, :id => scenario.id
    end
    let(:permission) { :edit_project }
    it_should_behave_like "a controller action which needs project permissions"
  end

  describe 'destroy.html' do
    let(:project)  { FactoryGirl.create(:project, :is_public  => false) }
    let(:scenario) { FactoryGirl.create(:scenario, :project_id => project.id) }

    def fetch
      post 'destroy', :project_id => project.id, :id => scenario.id
    end
    let(:permission) { :edit_project }
    def expect_redirect_to
      project_settings_path(project)
    end
    it_should_behave_like "a controller action which needs project permissions"
  end

  def project_settings_path(project)
    {:controller => 'projects', :action => 'settings', :tab => 'timelines', :id => project}
  end
end
