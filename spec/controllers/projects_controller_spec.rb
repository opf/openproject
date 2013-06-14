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
  before do
    Role.delete_all
    User.delete_all
  end

  before do
    @controller.stub!(:set_localization)

    @role = FactoryGirl.create(:non_member)
    @user = FactoryGirl.create(:admin)
    User.stub!(:current).and_return @user

    @params = {}
  end

  describe 'show' do
    render_views

    describe 'without wiki' do
      before do
        @project = FactoryGirl.create(:project)
        @project.reload # project contains wiki by default
        @project.wiki.destroy
        @project.reload
        @params[:id] = @project.id
      end

      it 'renders show' do
        get 'show', @params
        response.should be_success
        response.should render_template 'show'
      end

      it 'renders main menu without wiki menu item' do
        get 'show', @params

        assert_select "#main-menu a.Wiki", false # assert_no_select
      end
    end

    describe 'with wiki' do
      before do
        @project = FactoryGirl.create(:project)
        @project.reload # project contains wiki by default
        @params[:id] = @project.id
      end

      describe 'without custom wiki menu items' do
        it 'renders show' do
          get 'show', @params
          response.should be_success
          response.should render_template 'show'
        end

        it 'renders main menu with wiki menu item' do
          get 'show', @params

          assert_select "#main-menu a.Wiki", 'Wiki'
        end
      end

      describe 'with custom wiki menu item' do
        before do
          main_item = FactoryGirl.create(:wiki_menu_item, :wiki_id => @project.wiki.id, :name => 'Example', :title => 'Example')
          sub_item = FactoryGirl.create(:wiki_menu_item, :wiki_id => @project.wiki.id, :name => 'Sub', :title => 'Sub', :parent_id => main_item.id)
        end

        it 'renders show' do
          get 'show', @params
          response.should be_success
          response.should render_template 'show'
        end

        it 'renders main menu with wiki menu item' do
          get 'show', @params

          assert_select "#main-menu a.Example", 'Example'
        end

        it 'renders main menu with sub wiki menu item' do
          get 'show', @params

          assert_select "#main-menu a.Sub", 'Sub'
        end
      end
    end
  end
end

describe Api::V2::ProjectsController do
  let(:current_user) { FactoryGirl.create(:admin) }

  before do
    User.stub(:current).and_return current_user
  end

  describe 'w/o project_type scope' do
    describe 'index.xml' do
      describe 'with no project available' do
        it 'assigns an empty projects array' do
          get 'index', :format => 'xml'
          assigns(:projects).should == []
        end

        it 'renders the index template' do
          get 'index', :format => 'xml'
          response.should render_template('api/v2/projects/index', :formats => ["api"])
        end
      end

      describe 'with 3 projects available' do
        let(:current_user) { FactoryGirl.create(:user) }

        before do
          @visible_projects = [
            FactoryGirl.create(:project, :is_public => false),
            FactoryGirl.create(:project, :is_public => false)
          ].each do |project|
            FactoryGirl.create(:member,
                               :project => project,
                               :principal => current_user,
                               :roles => [FactoryGirl.create(:role)])
          end
          @visible_projects << FactoryGirl.create(:project, :is_public => true)

          @invisible_projects = [
            FactoryGirl.create(:project, :is_public => false),
            FactoryGirl.create(:project, :is_public => true,
                               :status => Project::STATUS_ARCHIVED)
          ]
        end

        it 'assigns an array with all of projects' do
          get 'index', :format => 'xml'
          assigns(:projects).map(&:identifier).should == @visible_projects.map(&:identifier)
        end

        it 'renders the index template' do
          get 'index', :format => 'xml'
          response.should render_template('api/v2/projects/index', :formats => ["api"])
        end
      end
    end

    describe 'show.xml' do
      describe 'public project' do
        let(:project) { FactoryGirl.create(:project, :is_public => true) }
        def fetch
          get 'show', :id => project.identifier, :format => 'xml'
        end
        it_should_behave_like "a controller action with unrestricted access"
      end

      describe 'private project' do
        before { $debug = true  }
        after  { $debug = false }

        let(:project) { FactoryGirl.create(:project, :is_public => false) }
        def fetch
          get 'show', :id => project.identifier, :format => 'xml'
        end
        it_should_behave_like "a controller action which needs project permissions"
      end


      describe 'with unknown project' do
        it 'raises ActiveRecord::RecordNotFound errors' do
          lambda do
            get 'show', :id => 'unknown_project', :format => 'xml'
          end.should raise_error(ActiveRecord::RecordNotFound)
        end
      end

      describe 'with an available project' do
        let(:project) { FactoryGirl.create(:project, :is_public => true) }

        it 'assigns the available project' do
          get 'show', :id => project.identifier, :format => 'xml'
          assigns(:project).should == project
        end

        it 'renders the show template' do
          get 'show', :id => project.identifier, :format => 'xml'
          response.should render_template('api/v2/projects/show', :formats => ["api"])
        end
      end
    end
  end
end
