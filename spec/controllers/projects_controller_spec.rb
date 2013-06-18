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
