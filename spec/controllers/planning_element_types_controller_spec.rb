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

describe PlanningElementTypesController do
  let (:current_user) { FactoryGirl.create(:admin) }

  before do
    User.stub(:current).and_return current_user
  end

  def enable_type(project, type)
    FactoryGirl.create(:enabled_planning_element_type,
                       :project_id => project.id,
                       :planning_element_type_id => type.id)
  end

  describe 'without project scope' do

    describe 'index.html' do
      def fetch
        get 'index'
      end
      it_should_behave_like "a controller action with require_admin"
    end

    describe 'new.html' do
      def fetch
        get 'new'
      end
      it_should_behave_like "a controller action with require_admin"
    end

    describe 'create.html' do
      def fetch
        post 'create', :planning_element_type => FactoryGirl.build(:planning_element_type).attributes
      end
      def expect_redirect_to
        planning_element_types_path
      end
      it_should_behave_like "a controller action with require_admin"
    end

    describe 'edit.html' do
      def fetch
        @available_type = FactoryGirl.create(:planning_element_type, :id => '1337')
        get 'edit', :id => '1337'
      end
      it_should_behave_like "a controller action with require_admin"
    end

    describe 'update.html' do
      def fetch
        @available_type = FactoryGirl.create(:planning_element_type, :id => '1337')
        get 'update', :id => '1337', :planning_element_type => {:name => 'blubs'}
      end
      def expect_redirect_to
        planning_element_types_path
      end
      it_should_behave_like "a controller action with require_admin"
    end

    describe "move.html" do
      def fetch
        @available_planning_element_type = FactoryGirl.create(:planning_element_type, :id => '1337')
        post 'move', :id => '1337', :planning_element_type => {:move_to => 'highest'}
      end
      def expect_redirect_to
        planning_element_types_path
      end
      it_should_behave_like "a controller action with require_admin"
    end

    describe 'confirm_destroy.html' do
      def fetch
        @available_type = FactoryGirl.create(:planning_element_type, :id => '1337')
        get 'confirm_destroy', :id => '1337'
      end
      it_should_behave_like "a controller action with require_admin"
    end

    describe 'destroy.html' do
      def fetch
        @available_type = FactoryGirl.create(:planning_element_type, :id => '1337')
        post 'destroy', :id => '1337'
      end
      def expect_redirect_to
        planning_element_types_path
      end
      it_should_behave_like "a controller action with require_admin"
    end
  end
end
