#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2021 the OpenProject GmbH
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
# See COPYRIGHT and LICENSE files for more details.
#++

require 'spec_helper'

describe WikiController, type: :controller do
  shared_let(:admin) { create :admin }

  shared_let(:project) do
    create(:project).tap(&:reload)
  end

  shared_let(:existing_page) do
    create(:wiki_page, wiki_id: project.wiki.id, title: 'ExistingPage')
  end

  shared_let(:existing_content) do
    # creating page contents
    create(:wiki_content, page_id: existing_page.id, author_id: admin.id)
  end


  describe 'actions' do
    before do
      allow(controller).to receive(:set_localization)
      login_as admin
    end

    shared_examples_for "a 'new' action" do
      it 'assigns @project to the current project' do
        get_page

        expect(assigns[:project]).to eq(project)
      end

      it 'assigns @page to a newly created wiki page' do
        get_page

        expect(assigns[:page]).to be_new_record
        expect(assigns[:page]).to be_kind_of WikiPage
        expect(assigns[:page].wiki).to eq(project.wiki)
      end

      it 'assigns @content to a newly created wiki content' do
        get_page

        expect(assigns[:content]).to be_new_record
        expect(assigns[:content]).to be_kind_of WikiContent
        expect(assigns[:content].page).to eq(assigns[:page])
      end

      it 'renders the new action' do
        get_page

        expect(response).to render_template 'new'
      end
    end

    describe 'new' do
      let(:get_page) { get 'new', params: { project_id: project } }

      it_should_behave_like "a 'new' action"
    end

    describe 'new_child' do
      let(:get_page) { get 'new_child', params: { project_id: project, id: existing_page.title } }

      it_should_behave_like "a 'new' action"

      it 'sets the parent page for the new page' do
        get_page

        expect(assigns[:page].parent).to eq(existing_page)
      end

      it 'renders 404 if used with an unknown page title' do
        get 'new_child', params: { project_id: project, id: 'foobar' }

        expect(response.status).to eq(404) # not found
      end
    end

    describe 'show' do
      let(:get_page) { get :show, params: { project_id: project, id: 'wiki' } }

      describe 'with an empty wiki and no permission to edit' do
        let(:view_role) { create :role, permissions: %w[view_wiki_pages] }
        let(:user) { create(:user, member_in_project: project, member_through_role: view_role) }

        it 'visiting the start page redirects to index' do
          login_as user
          get_page
          expect(response).to redirect_to action: :index
          expect(flash[:info]).to include I18n.t('wiki.page_not_editable_index')
        end
      end
    end

    describe 'edit' do
      it 'will link to a parent page if it was set' do
        get 'edit', params: { project_id: project, id: 'foobar' }, flash: { _related_wiki_page_id: 1234 }

        page = assigns[:page]
        expect(page.parent_id).to eq 1234
      end
    end

    describe 'create' do
      describe 'successful action' do
        it 'redirects to the show action' do
          post 'create',
               params: {
                 project_id: project,
                 content: { text: 'h1. abc', page: { title: 'abc' } }
               }

          expect(response).to redirect_to action: 'show', project_id: project, id: 'abc'
        end

        it 'saves a new WikiPage with proper content' do
          post 'create',
               params: {
                 project_id: project,
                 content: { text: 'h1. abc', page: { title: 'abc' } }
               }

          page = project.wiki.pages.find_by title: 'abc'
          expect(page).not_to be_nil
          expect(page.content.text).to eq('h1. abc')
        end
      end

      describe 'unsuccessful action' do
        it 'renders "wiki/new"' do
          post 'create',
               params: {
                 project_id: project,
                 content: { text: 'h1. abc', page: { title: '' } }
               }

          expect(response).to render_template('new')
        end

        it 'assigns project to work with new template' do
          post 'create',
               params: {
                 project_id: project,
                 content: { text: 'h1. abc', page: { title: '' } }
               }

          expect(assigns[:project]).to eq(project)
        end

        it 'assigns wiki to work with new template' do
          post 'create',
               params: {
                 project_id: project,
                 content: { text: 'h1. abc', page: { title: '' } }
               }

          expect(assigns[:wiki]).to eq(project.wiki)
          expect(assigns[:wiki]).not_to be_new_record
        end

        it 'assigns page to work with new template' do
          post 'create',
               params: {
                 project_id: project,
                 content: { text: 'h1. abc', page: { title: '' } }
               }

          expect(assigns[:page]).to be_new_record
          expect(assigns[:page].wiki.project).to eq(project)
          expect(assigns[:page].title).to eq('')
          expect(assigns[:page]).not_to be_valid
        end

        it 'assigns content to work with new template' do
          post 'create',
               params: {
                 project_id: project,
                 content: { text: 'h1. abc', page: { title: '' } }
               }

          expect(assigns[:content]).to be_new_record
          expect(assigns[:content].page.wiki.project).to eq(project)
          expect(assigns[:content].text).to eq('h1. abc')
        end
      end
    end

    describe 'update' do
      context 'when the page is locked' do
        before do
          existing_page.update!(protected: true)
        end

        it 'redirects to the show action' do
          post 'update',
               params: {
                 project_id: project,
                 id: existing_page.title,
                 content: { text: 'h1. abc', page: { title: 'foobar' } }
               }

          expect(response).to redirect_to action: 'show', project_id: project, id: 'foobar'
        end
      end
    end

    describe 'destroy' do
      describe 'successful action' do
        context 'when it is not the only wiki page' do
          let(:wiki) { project.wiki }
          let(:redirect_page_after_destroy) { wiki.find_page(wiki.start_page) || wiki.pages.first }

          before do
            create :wiki_page, wiki: wiki
          end

          it 'redirects to wiki#index' do
            delete :destroy, params: { project_id: project, id: existing_page }
            expect(response).to redirect_to action: 'index', project_id: project, id: redirect_page_after_destroy
          end
        end

        context 'when it is the only wiki page' do
          it 'redirects to projects#show' do
            delete :destroy, params: { project_id: project, id: existing_page }
            expect(response).to redirect_to project_path(project)
          end
        end
      end
    end
  end

  describe 'view related stuff' do
    render_views

    shared_let(:project) do
      create(:public_project).tap(&:reload)
    end

    before :each do
      allow(@controller).to receive(:set_localization)
      allow(Setting).to receive(:login_required?).and_return(false)

      @role = create(:non_member)

      @anon = User.anonymous.nil? ? create(:anonymous) : User.anonymous

      Role.anonymous.update name: I18n.t(:default_role_anonymous),
                            permissions: [:view_wiki_pages]

      allow(User).to receive(:current).and_return admin

      # creating pages
      @page_default = create(:wiki_page,
                                        wiki_id: project.wiki.id,
                                        title: 'Wiki')
      @page_with_content = create(:wiki_page,
                                             wiki_id: project.wiki.id,
                                             title: 'PagewithContent')
      @page_without_content = create(:wiki_page,
                                                wiki_id: project.wiki.id,
                                                title: 'PagewithoutContent')
      @unrelated_page = create(:wiki_page,
                                          wiki_id: project.wiki.id,
                                          title: 'UnrelatedPage')

      # creating page contents
      create(:wiki_content, page_id: @page_default.id,
                        author_id: admin.id)
      create(:wiki_content, page_id: @page_with_content.id,
                        author_id: admin.id)
      create(:wiki_content, page_id: @unrelated_page.id,
                        author_id: admin.id)

      # creating some child pages
      @children = {}
      [@page_with_content].each do |page|
        child_page = create(:wiki_page, wiki_id: project.wiki.id,
                                       parent_id: page.id,
                                       title: page.title + ' child')
        create(:wiki_content, page_id: child_page.id,
                          author_id: admin.id)

        @children[page] = child_page
      end
    end

    describe '- main menu links' do
      before do
        @main_menu_item_for_page_with_content = create(:wiki_menu_item,
                                                                  navigatable_id: project.wiki.id,
                                                                  title: 'Item for Page with Content',
                                                                  name: @page_with_content.slug)

        @main_menu_item_for_new_wiki_page = create(:wiki_menu_item,
                                                              navigatable_id: project.wiki.id,
                                                              title: 'Item for new WikiPage',
                                                              name: 'new-wiki-page')

        @other_menu_item = create(:wiki_menu_item,
                                             navigatable_id: project.wiki.id,
                                             title: 'Item for other page',
                                             name: @unrelated_page.slug)
      end

      shared_examples_for 'all wiki menu items' do
        it 'is inactive, when an unrelated page is shown' do
          get 'show', params: { id: @unrelated_page.slug, project_id: project.id }

          expect(response).to be_successful

          assert_select "#main-menu a.#{@wiki_menu_item.menu_identifier}-menu-item"
          assert_select "#main-menu a.#{@wiki_menu_item.menu_identifier}-menu-item.selected", false
        end

        it "is inactive, when another wiki menu item's page is shown" do
          get 'show', params: { id: @other_wiki_menu_item.name, project_id: project.id }

          expect(response).to be_successful
          expect(response.body).to have_selector('.main-menu--children a.selected', count: 0)

          assert_select "#main-menu a.#{@wiki_menu_item.menu_identifier}-menu-item"
          assert_select "#main-menu a.#{@wiki_menu_item.menu_identifier}-menu-item.selected", false
        end

        it 'is active, when the given wiki menu item is shown' do
          get 'show', params: { id: @wiki_menu_item.name, project_id: project.id }

          expect(response).to be_successful

          assert_select "#main-menu a.#{@wiki_menu_item.menu_identifier}-menu-item.selected"
        end
      end

      shared_examples_for 'all existing wiki menu items' do
        # TODO: Add tests for new and toc options within menu item
        it 'is active on parents item, when new page is shown' do
          get 'new_child', params: { id: @wiki_menu_item.name, project_id: project.identifier }

          expect(response).to be_successful

          assert_select "#main-menu a.#{@wiki_menu_item.menu_identifier}-menu-item.selected"
        end

        it 'is active, when a toc page is shown' do
          get 'index', params: { id: @wiki_menu_item.name, project_id: project.id }

          expect(response).to be_successful
          assert_select '#content h2', text: 'Table of Contents'
          assert_select "#main-menu a.#{@wiki_menu_item.menu_identifier}-menu-item.selected"
        end
      end

      shared_examples_for 'all wiki menu items with child pages' do
        it 'is active, when the given wiki menu item is an ancestor of the shown page' do
          get 'show', params: { id: @child_page.slug, project_id: project.id }

          expect(response).to be_successful
          expect(response.body).to have_selector('#main-menu a.selected', count: 1)

          assert_select "#main-menu a.#{@wiki_menu_item.menu_identifier}-menu-item.selected"
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
          @wiki_menu_item = create(:wiki_menu_item,
                                              navigatable_id: project.wiki.id,
                                              title: '?',
                                              name: 'help')
          @other_wiki_menu_item = @other_menu_item
        end

        it_should_behave_like 'all wiki menu items'
      end
    end

    describe '- wiki sidebar' do
      describe 'configure menu items link' do
        describe 'on a show page' do
          describe 'being authorized to configure menu items' do
            it 'is visible' do
              get 'show', params: { project_id: project.id }

              expect(response).to be_successful

              assert_select '#content a', 'Configure menu item'
            end
          end

          describe 'being unauthorized to configure menu items' do
            before do
              allow(User).to receive(:current).and_return @anon
            end

            it 'is invisible' do
              get 'show', params: { project_id: project.id }

              expect(response).to be_successful

              assert_select '#content a', text: 'Configure menu item', count: 0
            end
          end
        end
      end

      describe 'new child page link' do
        describe 'on an index page' do
          describe 'being authorized to edit wiki pages' do
            it 'is invisible' do
              get 'index', params: { project_id: project.id }

              expect(response).to be_successful

              assert_select '#content a', text: 'Wiki page', count: 0
            end
          end

          describe 'being unauthorized to edit wiki pages' do
            before do
              allow(User).to receive(:current).and_return @anon
            end

            it 'is invisible' do
              get 'index', params: { project_id: project.id }

              expect(response).to be_successful

              assert_select '#content a', text: 'Wiki page', count: 0
            end
          end
        end

        describe 'on a wiki page' do
          describe 'being authorized to edit wiki pages' do
            describe 'with a wiki page present' do
              it 'is visible' do
                get 'show',
                    params: { id: @page_with_content.title, project_id: project.identifier }

                expect(response).to be_successful

                # Expect to set back ref id
                expect(flash[:_related_wiki_page_id]).to eq @page_with_content.id

                path = new_child_project_wiki_path(project_id: project, id: @page_with_content.slug)

                assert_select "#content a[href='#{path}']", 'Wiki page'
              end
            end

            describe 'with no wiki page present' do
              it 'is invisible' do
                get 'show', params: { id: 'i-am-a-ghostpage', project_id: project.identifier }

                expect(response).to be_successful

                assert_select "#content a[href='#{new_child_project_wiki_path(project_id: project, id: 'i-am-a-ghostpage')}']",
                              text: 'Wiki page', count: 0
              end
            end
          end

          describe 'being unauthorized to edit wiki pages' do
            before do
              allow(User).to receive(:current).and_return @anon
            end

            it 'is invisible' do
              get 'show', params: { id: @page_with_content.title, project_id: project.identifier }

              expect(response).to be_successful

              assert_select '#content a', text: 'Wiki page', count: 0
            end
          end
        end
      end

      describe 'new page link' do
        describe 'on a show page' do
          describe 'being authorized to edit wiki pages' do
            it 'is visible' do
              get 'show', params: { project_id: project.id }

              expect(response).to be_successful

              assert_select ".toolbar-items a[href='#{new_child_project_wiki_path(project_id: project, id: 'wiki')}']",
                            'Wiki page'
            end
          end

          describe 'being unauthorized to edit wiki pages' do
            before do
              allow(User).to receive(:current).and_return @anon
            end

            it 'is invisible' do
              get 'show', params: { project_id: project.id }

              expect(response).to be_successful

              assert_select '.toolbar-items a', text: 'Wiki page', count: 0
            end
          end
        end
      end
    end
  end
end
