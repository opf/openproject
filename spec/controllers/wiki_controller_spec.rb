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

describe WikiController do
  before do
    Role.delete_all # removing me makes us faster
    User.delete_all # removing me makes us faster
    I18n.locale = :en
  end

  describe 'actions' do
    before do
      @controller.stub(:set_localization)

      @role = FactoryGirl.create(:non_member)
      @user = FactoryGirl.create(:admin)

      User.stub(:current).and_return @user

      @project = FactoryGirl.create(:project)
      @project.reload # to get the wiki into the proxy

      # creating pages
      @existing_page = FactoryGirl.create(:wiki_page, :wiki_id => @project.wiki.id,
                                                      :title   => 'ExistingPage')

      # creating page contents
      FactoryGirl.create(:wiki_content, :page_id   => @existing_page.id,
                                        :author_id => @user.id)
    end

    shared_examples_for "a 'new' action" do
      it 'assigns @project to the current project' do
        get_page

        assigns[:project].should == @project
      end

      it 'assigns @page to a newly created wiki page' do
        get_page

        assigns[:page].should be_new_record
        assigns[:page].should be_kind_of WikiPage
        assigns[:page].wiki.should == @project.wiki
      end

      it 'assigns @content to a newly created wiki content' do
        get_page

        assigns[:content].should be_new_record
        assigns[:content].should be_kind_of WikiContent
        assigns[:content].page.should == assigns[:page]
      end

      it 'renders the new action' do
        get_page

        response.should render_template 'new'
      end
    end

    describe 'new' do
      let(:get_page) { get 'new', :project_id => @project }

      it_should_behave_like "a 'new' action"
    end

    describe 'new_child' do
      let(:get_page) { get 'new_child', :project_id => @project, :id => @existing_page.title }

      it_should_behave_like "a 'new' action"

      it 'sets the parent page for the new page' do
        get_page

        assigns[:page].parent.should == @existing_page
      end

      it 'renders 404 if used with an unknown page title' do
        get 'new_child', :project_id => @project, :id => "foobar"

        response.status.should == 404 # not found
      end
    end

    describe 'create' do
      describe 'successful action' do
        it 'redirects to the show action' do
          post 'create',
               :project_id => @project,
               :page => {:title => "abc"},
               :content => {:text => "h1. abc"}

          response.should redirect_to :action => 'show', :project_id => @project, :id => 'Abc'
        end

        it 'saves a new WikiPage with proper content' do
          post 'create',
               :project_id => @project,
               :page => {:title => "abc"},
               :content => {:text => "h1. abc"}

          page = @project.wiki.pages.find_by_title 'Abc'
          page.should_not be_nil
          page.title.should == 'Abc'
          page.content.text.should == 'h1. abc'
        end
      end

      describe 'unsuccessful action' do
        it 'renders "wiki/new"' do
          post 'create',
               :project_id => @project,
               :page => {:title => ""},
               :content => {:text => "h1. abc"}

          response.should render_template('new')
        end

        it 'assigns project to work with new template' do
          post 'create',
               :project_id => @project,
               :page => {:title => ""},
               :content => {:text => "h1. abc"}

          assigns[:project].should == @project
        end

        it 'assigns wiki to work with new template' do
          post 'create',
               :project_id => @project,
               :page => {:title => ""},
               :content => {:text => "h1. abc"}

          assigns[:wiki].should == @project.wiki
          assigns[:wiki].should_not be_new_record
        end

        it 'assigns page to work with new template' do
          post 'create',
               :project_id => @project,
               :page => {:title => ""},
               :content => {:text => "h1. abc"}

          assigns[:page].should be_new_record
          assigns[:page].wiki.project.should == @project
          assigns[:page].title.should == ""
          assigns[:page].should_not be_valid
        end

        it 'assigns content to work with new template' do
          post 'create',
               :project_id => @project,
               :page => {:title => ""},
               :content => {:text => "h1. abc"}

          assigns[:content].should be_new_record
          assigns[:content].page.wiki.project.should == @project
          assigns[:content].text.should == 'h1. abc'
        end
      end
    end

    describe 'destroy' do
      describe 'successful action' do
        context 'when it is not the only wiki page' do
          let(:wiki) { @project.wiki }

          before do
            another_wiki_page = FactoryGirl.create :wiki_page, wiki: wiki
          end

          it 'redirects to wiki#index' do
            delete :destroy, project_id: @project, id: @existing_page
            response.should redirect_to action: 'index', project_id: @project
          end
        end

        context 'when it is the only wiki page' do
          it 'redirects to projects#show' do
            delete :destroy, project_id: @project, id: @existing_page
            response.should redirect_to project_path(@project)
          end
        end
      end
    end
  end # describe 'actions'

  describe 'view related stuff' do
    render_views

    before :each do
      @controller.stub(:set_localization)
      Setting.stub(:login_required?).and_return(false)

      @role = FactoryGirl.create(:non_member)
      @user = FactoryGirl.create(:admin)


      @anon = User.anonymous.nil? ? FactoryGirl.create(:anonymous) : User.anonymous

      Role.anonymous.update_attributes :name => I18n.t(:default_role_anonymous),
                                       :permissions => [:view_wiki_pages]

      User.stub(:current).and_return @user

      @project = FactoryGirl.create(:project)
      @project.reload # to get the wiki into the proxy

      # creating pages
      @page_default = FactoryGirl.create(:wiki_page, :wiki_id => @project.wiki.id,
                                     :title   => 'Wiki')
      @page_with_content = FactoryGirl.create(:wiki_page, :wiki_id => @project.wiki.id,
                                                      :title   => 'PagewithContent')
      @page_without_content = FactoryGirl.create(:wiki_page, :wiki_id => @project.wiki.id,
                                                      :title   => 'PagewithoutContent')
      @unrelated_page = FactoryGirl.create(:wiki_page, :wiki_id => @project.wiki.id,
                                                   :title   => 'UnrelatedPage')

      # creating page contents
      FactoryGirl.create(:wiki_content, :page_id   => @page_default.id,
                                    :author_id => @user.id)
      FactoryGirl.create(:wiki_content, :page_id   => @page_with_content.id,
                                    :author_id => @user.id)
      FactoryGirl.create(:wiki_content, :page_id   => @unrelated_page.id,
                                    :author_id => @user.id)

      # creating some child pages
      @children = {}
      [@page_with_content].each do |page|
        child_page = FactoryGirl.create(:wiki_page, :wiki_id   => @project.wiki.id,
                                                :parent_id => page.id,
                                                :title     => page.title + " child")
        FactoryGirl.create(:wiki_content, :page_id => child_page.id,
                                      :author_id => @user.id)

        @children[page] = child_page
      end
    end

    describe '- main menu links' do
      before do
        @main_menu_item_for_page_with_content = FactoryGirl.create(:wiki_menu_item, :wiki_id => @project.wiki.id,
                                                               :name    => 'Item for Page with Content',
                                                               :title   => @page_with_content.title)

        @main_menu_item_for_new_wiki_page = FactoryGirl.create(:wiki_menu_item, :wiki_id => @project.wiki.id,
                                                           :name    => 'Item for new WikiPage',
                                                           :title   => 'NewWikiPage')

        @other_menu_item = FactoryGirl.create(:wiki_menu_item, :wiki_id => @project.wiki.id,
                                                           :name    => 'Item for other page',
                                                           :title   => @unrelated_page.title)

      end

      shared_examples_for 'all wiki menu items' do
        it "is inactive, when an unrelated page is shown" do
          get 'show', :id => @unrelated_page.title, :project_id => @project.id

          response.should be_success
          response.should have_exactly_one_selected_menu_item_in(:project_menu)

          assert_select "#main-menu a.#{@wiki_menu_item.item_class}"
          assert_select "#main-menu a.#{@wiki_menu_item.item_class}.selected", false
        end

        it "is inactive, when another wiki menu item's page is shown" do
          get 'show', :id => @other_wiki_menu_item.title, :project_id => @project.id

          response.should be_success
          response.should have_exactly_one_selected_menu_item_in(:project_menu)

          assert_select "#main-menu a.#{@wiki_menu_item.item_class}"
          assert_select "#main-menu a.#{@wiki_menu_item.item_class}.selected", false
        end

        it 'is active, when the given wiki menu item is shown' do
          get 'show', :id => @wiki_menu_item.title, :project_id => @project.id

          response.should be_success
          response.should have_exactly_one_selected_menu_item_in(:project_menu)

          assert_select "#main-menu a.#{@wiki_menu_item.item_class}.selected"
        end
      end


      shared_examples_for 'all existing wiki menu items' do
        #TODO: Add tests for new and toc options within menu item
        it "is active on parents item, when new page is shown" do
          get 'new_child', :id => @wiki_menu_item.title, :project_id => @project.identifier

          response.should be_success
          response.should have_no_selected_menu_item_in(:project_menu)

          assert_select "#main-menu a.#{@wiki_menu_item.item_class}"
          assert_select "#main-menu a.#{@wiki_menu_item.item_class}.selected", false
        end

        it 'is inactive, when a toc page is shown' do
          get 'index', :id => @wiki_menu_item.title, :project_id => @project.id

          response.should be_success
          response.should have_no_selected_menu_item_in(:project_menu)

          assert_select "#main-menu a.#{@wiki_menu_item.item_class}"
          assert_select "#main-menu a.#{@wiki_menu_item.item_class}.selected", false
        end
      end

      shared_examples_for 'all wiki menu items with child pages' do
        it 'is active, when the given wiki menu item is an ancestor of the shown page' do
          get 'show', :id => @child_page.title, :project_id => @project.id

          response.should be_success
          response.should have_exactly_one_selected_menu_item_in(:project_menu)

          assert_select "#main-menu a.#{@wiki_menu_item.item_class}.selected"
        end
      end


      describe '- wiki menu item pointing to a saved wiki page' do
        before do
          @wiki_menu_item = @main_menu_item_for_page_with_content
          @other_wiki_menu_item = @other_menu_item
          @child_page = @children[@page_with_content]
        end

        it_should_behave_like 'all wiki menu items'
        it_should_behave_like 'all existing wiki menu items'
        it_should_behave_like 'all wiki menu items with child pages'
      end

      describe '- wiki menu item pointing to a new wiki page' do
        before do
          @wiki_menu_item = @main_menu_item_for_new_wiki_page
          @other_wiki_menu_item = @other_menu_item
        end

        it_should_behave_like 'all wiki menu items'
      end

      describe '- wiki_menu_item containing special chars only' do
        before do
          @wiki_menu_item = FactoryGirl.create(:wiki_menu_item, :wiki_id => @project.wiki.id,
                                                            :name    => '?',
                                                            :title   => 'Help')
          @other_wiki_menu_item = @other_menu_item
        end

        it_should_behave_like 'all wiki menu items'
      end
    end

    describe '- wiki sidebar' do
      describe 'configure menu items link' do
        describe 'on a show page' do
          describe "being authorized to configure menu items" do
            it 'is visible' do
              get 'show', :project_id => @project.id

              response.should be_success

              assert_select '#content a', 'Configure menu item'
            end
          end

          describe "being unauthorized to configure menu items" do
            before do
              User.stub(:current).and_return @anon
            end

            it 'is invisible' do
              get 'show', :project_id => @project.id

              response.should be_success

              assert_select '#content a', :text => 'Configure menu item', :count => 0
            end
          end
        end
      end

      describe 'new child page link' do
        describe 'on an index page' do
          describe "being authorized to edit wiki pages" do
            it 'is invisible' do
              get 'index', :project_id => @project.id

              response.should be_success

              assert_select '#content a', :text => 'Create new child page', :count => 0
            end
          end

          describe "being unauthorized to edit wiki pages" do
            before do
              User.stub(:current).and_return @anon
            end

            it 'is invisible' do
              get 'index', :project_id => @project.id

              response.should be_success

              assert_select '#content a', :text => 'Create new child page', :count => 0
            end
          end
        end

        describe 'on a wiki page' do
          describe "being authorized to edit wiki pages" do
            describe "with a wiki page present" do
              it "is visible" do
                get 'show', :id => @page_with_content.title, :project_id => @project.identifier

                response.should be_success

                assert_select "#content a[href=#{wiki_new_child_path(:project_id => @project, :id => @page_with_content.title)}]", 'Create new child page'
              end
            end


            describe "with no wiki page present" do
              it 'is invisible' do
                get 'show', :id => 'i-am-a-ghostpage', :project_id => @project.identifier

                response.should be_success

                assert_select "#content a[href=#{wiki_new_child_path(:project_id => @project, :id => 'i-am-a-ghostpage')}]",
                                :text => 'Create new child page', :count => 0
              end
            end
          end

          describe "being unauthorized to edit wiki pages" do
            before do
              User.stub(:current).and_return @anon
            end

            it 'is invisible' do
              get 'show', :id => @page_with_content.title, :project_id => @project.identifier

              response.should be_success

              assert_select '#content a', :text => 'Create new child page', :count => 0
            end
          end
        end
      end

      describe 'new page link' do
        describe 'on an index page' do
          describe "being authorized to edit wiki pages" do
            it 'is visible' do
              get 'index', :project_id => @project.id

              response.should be_success

              assert_select ".menu_root a[href=#{wiki_new_child_path(:project_id => @project, :id => 'Wiki')}]", 'Create new child page'
            end
          end

          describe "being unauthorized to edit wiki pages" do
            before do
              User.stub(:current).and_return @anon
            end

            it 'is invisible' do
              get 'index', :project_id => @project.id

              response.should be_success

              assert_select '.menu_root a', :text => 'Create new child page', :count => 0
            end
          end
        end

        describe 'on a wiki page' do
          describe "being authorized to edit wiki pages" do
            it 'is visible' do
              get 'show', :id => @page_with_content.title, :project_id => @project.identifier

              response.should be_success

              assert_select ".menu_root a[href=#{wiki_new_child_path(:project_id => @project, :id => 'Wiki')}]", 'Create new child page'
            end
          end

          describe "being unauthorized to edit wiki pages" do
            before do
              User.stub(:current).and_return @anon
            end

            it 'is invisible' do
              get 'show', :id => @page_with_content.title, :project_id => @project.identifier

              response.should be_success

              assert_select '.menu_root a', :text => 'Create new child page', :count => 0
            end
          end
        end
      end
    end
  end
end
