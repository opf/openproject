#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
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

require "spec_helper"

RSpec.describe WikiController do
  shared_let(:admin) { create(:admin) }

  shared_let(:project) do
    create(:project).tap(&:reload)
  end
  shared_let(:wiki) { project.wiki }

  shared_let(:existing_page) do
    create(:wiki_page, wiki_id: project.wiki.id, title: "ExistingPage", author: admin)
  end

  describe "actions" do
    before do
      allow(controller).to receive(:set_localization)
    end

    current_user { admin }

    describe "index" do
      before do
        get :index, params: { project_id: project.identifier }
      end

      it "is successful" do
        expect(response)
          .to have_http_status(:ok)
      end

      it "renders the index template" do
        expect(response)
          .to render_template(:index)
      end

      it "assigns pages" do
        expect(assigns[:pages])
          .to eq project.wiki.pages
      end
    end

    shared_examples_for "a 'new' action" do
      it "assigns @project to the current project" do
        get_page

        expect(assigns[:project]).to eq(project)
      end

      it "assigns @page to a newly created wiki page" do
        get_page

        expect(assigns[:page]).to be_new_record
        expect(assigns[:page]).to be_a WikiPage
        expect(assigns[:page].wiki).to eq(project.wiki)
      end

      it "renders the new action" do
        get_page

        expect(response).to render_template "new"
      end
    end

    describe "new" do
      let(:get_page) { get "new", params: { project_id: project } }

      it_behaves_like "a 'new' action"
    end

    describe "new_child" do
      let(:get_page) { get "new_child", params: { project_id: project, id: existing_page.title } }

      it_behaves_like "a 'new' action"

      it "sets the parent page for the new page" do
        get_page

        expect(assigns[:page].parent).to eq(existing_page)
      end

      it "renders 404 if used with an unknown page title" do
        get "new_child", params: { project_id: project, id: "foobar" }

        expect(response).to have_http_status(:not_found)
      end
    end

    describe "show" do
      let(:permissions) { %w[view_wiki_pages] }
      let(:user) { create(:user, member_with_permissions: { project => permissions }) }

      current_user { user }

      before do
        get_page
      end

      context "when querying for an existing page" do
        let(:get_page) { get :show, params: { project_id: project, id: existing_page.title } }

        it "is a success" do
          expect(response)
            .to have_http_status(:ok)
        end

        it "renders the show template" do
          expect(response)
            .to render_template(:show)
        end

        it "assigns the page" do
          expect(assigns[:page])
            .to eql existing_page
        end
      end

      context "when querying for the wiki root page with edit permissions" do
        let(:get_page) { get :show, params: { project_id: project, id: "wiki" } }
        let(:permissions) { %w[view_wiki_pages edit_wiki_pages] }

        it "is a success" do
          expect(response)
            .to have_http_status(:ok)
        end

        it "renders the new template" do
          expect(response)
            .to render_template(:new)
        end

        it "assigns a new page that is unpersisted" do
          expect(assigns[:page])
            .to be_a WikiPages::AtVersion

          expect(assigns[:page])
            .to be_new_record
        end
      end

      context "when querying for an unexisting page with edit permissions" do
        let(:get_page) { get :show, params: { project_id: project, id: "new_page" } }
        let(:permissions) { %w[view_wiki_pages edit_wiki_pages] }

        it "is a success" do
          expect(response)
            .to have_http_status(:ok)
        end

        it "renders the new template" do
          expect(response)
            .to render_template(:new)
        end

        it "assigns a new page that is unpersisted" do
          expect(assigns[:page])
            .to be_a WikiPages::AtVersion

          expect(assigns[:page])
            .to be_new_record
        end
      end

      context "when querying for no specific page" do
        let(:get_page) do
          project.wiki.update_column(:start_page, existing_page.title)

          get :show, params: { project_id: project }
        end

        it "is a success" do
          expect(response)
            .to have_http_status(:ok)
        end

        it "renders the show template" do
          expect(response)
            .to render_template(:show)
        end

        it "assigns the wiki start page" do
          expect(assigns[:page])
            .to eql existing_page
        end
      end

      context "when querying for the wiki root page without edit permissions" do
        let(:get_page) { get :show, params: { project_id: project, id: "wiki" } }

        it "redirects to index" do
          expect(response).to redirect_to action: :index
        end

        it "shows a flash info" do
          expect(flash[:info]).to include I18n.t("wiki.page_not_editable_index")
        end
      end

      context "when querying for a non existing page without edit permissions" do
        let(:get_page) { get :show, params: { project_id: project, id: "new_page" } }

        it "returns 404" do
          expect(response)
            .to have_http_status(:not_found)
        end
      end
    end

    describe "edit" do
      let(:permissions) { %i[view_wiki_pages edit_wiki_pages] }

      let(:params) do
        { project_id: project, id: existing_page.title }
      end
      let(:flash) do
        {}
      end

      current_user { create(:user, member_with_permissions: { project => permissions }) }

      before do
        get :edit, params:, flash:
      end

      context "with an existing wiki page" do
        let(:params) do
          { project_id: project, id: existing_page.title }
        end

        it "is sucessful" do
          expect(response)
            .to have_http_status(:ok)
        end

        it "renders the edit template" do
          expect(response)
            .to render_template :edit
        end

        it "assigns the page" do
          expect(assigns[:page])
            .to eq existing_page

          expect(assigns[:page])
            .not_to be_changed
        end
      end

      context "with an existing wiki page that is protected" do
        let(:params) do
          existing_page.update_column(:protected, true)
          { project_id: project, id: existing_page.title }
        end

        it "is forbiddend" do
          expect(response)
            .to have_http_status(:forbidden)
        end
      end

      context "with an existing wiki page that is protected and having the necessary permission" do
        let(:permissions) do
          existing_page.update_column(:protected, true)

          %i[view_wiki_pages edit_wiki_pages protect_wiki_pages]
        end

        it "is sucessful" do
          expect(response)
            .to have_http_status(:ok)
        end

        it "renders the edit template" do
          expect(response)
            .to render_template :edit
        end

        it "assigns the page" do
          expect(assigns[:page])
            .to eq existing_page

          expect(assigns[:page])
            .not_to be_changed
        end
      end

      context "with a related wiki page in the flash and a non existing wiki page" do
        let(:flash) { { _related_wiki_page_id: 1234 } }
        let(:params) do
          { project_id: project, id: "foobar" }
        end

        it "is sucessful" do
          expect(response)
            .to have_http_status(:ok)
        end

        it "renders the edit template" do
          expect(response)
            .to render_template :edit
        end

        it "assigns @page to a new wiki page with the parent id set" do
          expect(assigns[:page])
            .to be_a WikiPages::AtVersion

          expect(assigns[:page])
            .to be_new_record

          expect(assigns[:page].parent_id)
            .to eql flash[:_related_wiki_page_id]
        end
      end
    end

    describe "create" do
      describe "successful action" do
        it "redirects to the show action" do
          post "create",
               params: {
                 project_id: project,
                 page: { text: "h1. abc", title: "abc" }
               }

          expect(response).to redirect_to action: "show", project_id: project, id: "abc"
        end

        it "saves a new WikiPage with proper content" do
          post "create",
               params: {
                 project_id: project,
                 page: { text: "h1. abc", title: "abc" }
               }

          page = project.wiki.pages.find_by title: "abc"
          expect(page).not_to be_nil
          expect(page.text).to eq("h1. abc")
        end
      end

      describe "unsuccessful action" do
        it 'renders "wiki/new"' do
          post "create",
               params: {
                 project_id: project,
                 page: { text: "h1. abc", title: "" }
               }

          expect(response).to render_template("new")
        end

        it "assigns project to work with new template" do
          post "create",
               params: {
                 project_id: project,
                 page: { text: "h1. abc", title: "" }
               }

          expect(assigns[:project]).to eq(project)
        end

        it "assigns wiki to work with new template" do
          post "create",
               params: {
                 project_id: project,
                 page: { text: "h1. abc", title: "" }
               }

          expect(assigns[:wiki]).to eq(project.wiki)
          expect(assigns[:wiki]).not_to be_new_record
        end

        it "assigns page to work with new template" do
          post "create",
               params: {
                 project_id: project,
                 page: { text: "h1. abc", title: "" }
               }

          expect(assigns[:page]).to be_new_record
          expect(assigns[:page].wiki.project).to eq(project)
          expect(assigns[:page].title).to eq("")
          expect(assigns[:page].text).to eq("h1. abc")
          expect(assigns[:page]).not_to be_valid
        end
      end
    end

    describe "update" do
      context "when the page is locked" do
        before do
          existing_page.update!(protected: true)
        end

        it "redirects to the show action" do
          post "update",
               params: {
                 project_id: project,
                 id: existing_page.title,
                 page: { text: "h1. abc", title: "foobar" }
               }

          expect(response).to redirect_to action: "show", project_id: project, id: "foobar"
        end
      end
    end

    describe "destroy" do
      shared_let(:parent_page) { create(:wiki_page, wiki:) }
      shared_let(:child_page) { create(:wiki_page, wiki:, parent: parent_page) }

      let(:redirect_page_after_destroy) { wiki.find_page(wiki.start_page) || wiki.pages.first }

      let(:params) do
        { project_id: project, id: existing_page }
      end

      subject do
        delete(:destroy, params:)

        response
      end

      context "when it is not the only wiki page" do
        it "redirects to wiki#index" do
          expect(subject)
            .to redirect_to action: "index", project_id: project, id: redirect_page_after_destroy
        end

        it "destroys the page" do
          expect { subject }
            .to change { WikiPage.where(id: existing_page.id).count }
                  .from(1)
                  .to(0)
        end
      end

      context "when it is the only wiki page" do
        before do
          WikiPage.where.not(id: existing_page.id).delete_all
        end

        it "redirects to projects#show" do
          expect(subject)
            .to redirect_to project_path(project)
        end

        it "destroys the page" do
          expect { subject }
            .to change { WikiPage.where(id: existing_page.id).count }
                  .from(1)
                  .to(0)
        end
      end

      context "when destroying a child" do
        let(:params) do
          { project_id: project, id: child_page }
        end

        it "redirects to wiki#index" do
          expect(subject)
            .to redirect_to action: "index", project_id: project, id: redirect_page_after_destroy
        end

        it "destroys the page" do
          expect { subject }
            .to change { WikiPage.where(id: child_page.id).count }
                  .from(1)
                  .to(0)
        end
      end

      context "when destroying a parent without specifying todo" do
        let(:params) do
          { project_id: project, id: parent_page }
        end

        it "responds with success" do
          expect(subject)
            .to have_http_status(:ok)
        end

        it "destroys the page" do
          expect { subject }
            .not_to change(WikiPage, :count)
        end
      end

      context "when destroying a parent with nullify" do
        let(:params) do
          { project_id: project, id: parent_page, todo: "nullify" }
        end

        it "redirects to wiki#index" do
          expect(subject)
            .to redirect_to action: "index", project_id: project, id: redirect_page_after_destroy
        end

        it "destroys the page" do
          expect { subject }
            .to change { WikiPage.where(id: parent_page.id).count }
                  .from(1)
                  .to(0)
        end

        it "sets the parent_id of the child to nil" do
          subject

          expect(child_page.parent_id)
            .to be_nil
        end
      end

      context "when destroying a parent with todo = destroy" do
        let(:params) do
          { project_id: project, id: parent_page, todo: "destroy" }
        end

        it "redirects to wiki#index" do
          expect(subject)
            .to redirect_to action: "index", project_id: project, id: redirect_page_after_destroy
        end

        it "destroys the page" do
          expect { subject }
            .to change { WikiPage.where(id: [parent_page, child_page]).count }
                  .from(2)
                  .to(0)
        end
      end

      context "when destroying a parent with reassign" do
        let(:params) do
          { project_id: project, id: parent_page, todo: "reassign", reassign_to_id: existing_page.id }
        end

        it "redirects to wiki#index" do
          expect(subject)
            .to redirect_to action: "index", project_id: project, id: redirect_page_after_destroy
        end

        it "destroys the page" do
          expect { subject }
            .to change { WikiPage.where(id: parent_page).count }
                  .from(1)
                  .to(0)
        end

        it "sets the parent_id of the child to the specified page" do
          subject

          expect(child_page.parent_id)
            .to eq existing_page.id
        end
      end
    end

    describe "rename" do
      shared_let(:parent_page) { create(:wiki_page, wiki:) }
      shared_let(:child_page) { create(:wiki_page, wiki:, parent: parent_page) }

      let(:permissions) { %i[view_wiki_pages rename_wiki_pages edit_wiki_pages] }

      let(:params) do
        { project_id: project, id: existing_page.title }
      end

      let(:request) do
        get :rename, params:
      end

      current_user { create(:user, member_with_permissions: { project => permissions }) }

      subject do
        request

        response
      end

      context "when getting for a page" do
        it "is success" do
          expect(subject)
            .to have_http_status(:ok)
        end

        it "renders the template" do
          expect(subject)
            .to render_template :rename
        end
      end

      context "when getting for a child page" do
        let(:params) do
          { project_id: project, id: child_page.title }
        end

        it "is success" do
          expect(subject)
            .to have_http_status(:ok)
        end

        it "renders the template" do
          expect(subject)
            .to render_template :rename
        end
      end

      context "when getting for a page without permissions" do
        let(:permissions) { %i[view_wiki_pages] }

        it "is forbidden" do
          expect(subject)
            .to have_http_status(:forbidden)
        end
      end

      context "when patching with redirect" do
        let(:new_title) { "The new page title" }
        let!(:old_title) { existing_page.title }

        let(:params) do
          {
            project_id: project,
            id: existing_page.title,
            page: {
              title: new_title,
              redirect_existing_links: 1
            }
          }
        end

        let(:request) do
          patch :rename, params:
        end

        it "redirects to the show page with the altered name" do
          expect(subject)
            .to redirect_to action: "show", project_id: project.identifier, id: "the-new-page-title"
        end

        it "renames the page" do
          subject

          expect(existing_page.reload.title)
            .to eql new_title
        end

        it "finds the page by the old name" do
          subject

          expect(wiki.find_page(old_title))
            .to eql existing_page
        end
      end

      context "when patching without redirect" do
        let(:new_title) { "The new page title" }
        let!(:old_title) { existing_page.title }

        let(:params) do
          {
            project_id: project,
            id: existing_page.title,
            page: {
              title: new_title,
              redirect_existing_links: "0"
            }
          }
        end

        let(:request) do
          patch :rename, params:
        end

        it "redirects to the show page with the altered name" do
          expect(subject)
            .to redirect_to action: "show", project_id: project.identifier, id: "the-new-page-title"
        end

        it "renames the page" do
          subject

          expect(existing_page.reload.title)
            .to eql new_title
        end

        it "does not find the page by the old name" do
          subject

          expect(wiki.find_page(old_title))
            .to be_nil
        end
      end
    end

    describe "diffs" do
      let!(:journal_from) { existing_page.journals.last }
      let!(:journal_to) do
        existing_page.text = "new_text"
        existing_page.save

        existing_page.journals.reload.last
      end

      let(:permissions) { %i[view_wiki_pages view_wiki_edits] }

      let(:version_from) { journal_from.version.to_s }
      let(:version_to) { journal_to.version.to_s }

      let(:params) do
        {
          project_id: project,
          id: existing_page.title,
          version_to:,
          version_from:
        }
      end

      let(:request) do
        get :diff, params:
      end

      current_user { create(:user, member_with_permissions: { project => permissions }) }

      subject do
        request

        response
      end

      it "is success" do
        expect(subject)
          .to have_http_status(:ok)
      end

      it "renders the template" do
        expect(subject)
          .to render_template :diff
      end

      it "assigns html_diff" do
        subject

        expect(assigns[:html_diff])
          .to be_a(String)
      end

      it "passes the params to the diff renderer" do
        expect_any_instance_of(WikiPage).to receive(:diff).with(version_to, version_from)

        subject
      end
    end

    describe "annotates" do
      let!(:journal_from) { existing_page.journals.last }
      let!(:journal_to) do
        existing_page.text = "new_text"
        existing_page.save

        existing_page.journals.reload.last
      end

      let(:permissions) { %i[view_wiki_pages view_wiki_edits] }

      let(:params) do
        { project_id: project, id: existing_page.title, version: journal_to.version }
      end

      let(:request) do
        get :annotate, params:
      end

      current_user { create(:user, member_with_permissions: { project => permissions }) }

      subject do
        request

        response
      end

      it "is success" do
        expect(subject)
          .to have_http_status(:ok)
      end

      it "renders the template" do
        expect(subject)
          .to render_template :annotate
      end
    end

    describe "export" do
      let(:permissions) { %i[view_wiki_pages export_wiki_pages] }

      current_user { create(:user, member_with_permissions: { project => permissions }) }

      before do
        get :export, params: { project_id: project.identifier }
      end

      it "is successful" do
        expect(response)
          .to have_http_status(:ok)
      end

      it "assigns pages" do
        expect(assigns[:pages])
          .to eq project.wiki.pages
      end

      it "is an html response" do
        expect(response.content_type)
          .to eq "text/html"
      end

      context "for an unauthorized user" do
        let(:permissions) { %i[view_wiki_pages] }

        it "prevents access" do
          expect(response)
            .to have_http_status(:forbidden)
        end
      end
    end

    describe "protect" do
      let(:permissions) { %i[view_wiki_pages protect_wiki_pages] }

      let(:params) do
        { project_id: project, id: existing_page.title, protected: "1" }
      end

      let(:request) do
        post :protect, params:
      end

      current_user { create(:user, member_with_permissions: { project => permissions }) }

      subject do
        request
        response
      end

      context "with an existing wiki page" do
        it "set the protected property of the page" do
          expect { subject }
            .to change { existing_page.reload.protected? }
                  .from(false)
                  .to(true)
        end

        it "redirects to the show page" do
          expect(subject)
            .to redirect_to action: "show", project_id: project.identifier, id: existing_page.title.downcase
        end
      end

      context "with an existing wiki page that is protected" do
        let(:permissions) do
          existing_page.update_column :protected, true

          %i[view_wiki_pages protect_wiki_pages]
        end

        let(:params) do
          { project_id: project, id: existing_page.title, protected: "0" }
        end

        it "set the protected property of the page" do
          expect { subject }
            .to change { existing_page.reload.protected? }
                  .from(true)
                  .to(false)
        end

        it "redirects to the show page" do
          expect(subject)
            .to redirect_to action: "show", project_id: project.identifier, id: existing_page.title.downcase
        end
      end

      context "with an existing wiki page but missing permissions" do
        let(:permissions) do
          %i[view_wiki_pages]
        end

        it "does not change the protected property of the page" do
          expect { subject }
            .not_to change { existing_page.reload.protected? }
        end

        it "return forbidden" do
          expect(subject)
            .to have_http_status(:forbidden)
        end
      end
    end

    describe "history" do
      let(:permissions) { %i[view_wiki_edits] }

      current_user { create(:user, member_with_permissions: { project => permissions }) }

      before do
        get :history, params: { project_id: project.identifier, id: existing_page.title }
      end

      it "is successful" do
        expect(response)
          .to have_http_status(:ok)
      end

      it "renders the template" do
        expect(response)
          .to render_template :history
      end

      it "assigns versions" do
        expect(assigns[:versions])
          .to eq existing_page.journals
      end

      context "for a non existing page" do
        before do
          get :history, params: { project_id: project.identifier, id: "bogus" }
        end

        it "states not found" do
          expect(response)
            .to have_http_status(:not_found)
        end
      end
    end
  end

  describe "view related stuff" do
    render_views

    shared_let(:project) do
      create(:public_project).tap(&:reload)
    end

    # creating pages
    let!(:page_with_content) do
      create(:wiki_page,
             wiki_id: project.wiki.id,
             title: "PagewithContent",
             author_id: admin.id)
    end
    let!(:page_default) do
      create(:wiki_page,
             wiki_id: project.wiki.id,
             title: "Wiki",
             author_id: admin.id)
    end
    let!(:unrelated_page) do
      create(:wiki_page,
             wiki_id: project.wiki.id,
             title: "UnrelatedPage",
             author_id: admin.id)
    end

    let(:child_page) do
      create(:wiki_page,
             wiki_id: project.wiki.id,
             parent_id: page_with_content.id,
             title: "#{page_with_content.title} child",
             author_id: admin.id)
    end

    before do
      allow(@controller).to receive(:set_localization)
      allow(Setting).to receive(:login_required?).and_return(false)

      @role = create(:non_member)

      @anon = User.anonymous.nil? ? create(:anonymous) : User.anonymous

      ProjectRole.anonymous.update permissions: [:view_wiki_pages]
    end

    current_user { admin }

    describe "- main menu links" do
      before do
        @main_menu_item_for_page_with_content = create(:wiki_menu_item,
                                                       navigatable_id: project.wiki.id,
                                                       title: "Item for Page with Content",
                                                       name: page_with_content.slug)

        @main_menu_item_for_new_wiki_page = create(:wiki_menu_item,
                                                   navigatable_id: project.wiki.id,
                                                   title: "Item for new WikiPage",
                                                   name: "new-wiki-page")

        @other_menu_item = create(:wiki_menu_item,
                                  navigatable_id: project.wiki.id,
                                  title: "Item for other page",
                                  name: unrelated_page.slug)
      end

      shared_examples_for "all wiki menu items" do
        it "is inactive, when an unrelated page is shown" do
          get "show", params: { id: unrelated_page.slug, project_id: project.id }

          expect(response).to be_successful

          assert_select "#main-menu a.#{@wiki_menu_item.menu_identifier}-menu-item"
          assert_select "#main-menu a.#{@wiki_menu_item.menu_identifier}-menu-item.selected", false
        end

        it "is inactive, when another wiki menu item's page is shown" do
          get "show", params: { id: @other_wiki_menu_item.name, project_id: project.id }

          expect(response).to be_successful
          expect(response.body).to have_css(".main-menu--children a.selected", count: 0)

          assert_select "#main-menu a.#{@wiki_menu_item.menu_identifier}-menu-item"
          assert_select "#main-menu a.#{@wiki_menu_item.menu_identifier}-menu-item.selected", false
        end

        it "is active, when the given wiki menu item is shown" do
          get "show", params: { id: @wiki_menu_item.name, project_id: project.id }

          expect(response).to be_successful

          assert_select "#main-menu a.#{@wiki_menu_item.menu_identifier}-menu-item.selected"
        end
      end

      shared_examples_for "all existing wiki menu items" do
        # TODO: Add tests for new and toc options within menu item
        it "is active on parents item, when new page is shown" do
          get "new_child", params: { id: @wiki_menu_item.name, project_id: project.identifier }

          expect(response).to be_successful

          assert_select "#main-menu a.#{@wiki_menu_item.menu_identifier}-menu-item.selected"
        end

        it "is active, when a toc page is shown" do
          get "index", params: { id: @wiki_menu_item.name, project_id: project.id }

          expect(response).to be_successful
          assert_select "#content h2", text: "Table of Contents"
          assert_select "#main-menu a.#{@wiki_menu_item.menu_identifier}-menu-item.selected"
        end
      end

      shared_examples_for "all wiki menu items with child pages" do
        it "is active, when the given wiki menu item is an ancestor of the shown page" do
          get "show", params: { id: child_page.slug, project_id: project.id }

          expect(response).to be_successful
          expect(response.body).to have_css("#main-menu a.selected", count: 1)

          assert_select "#main-menu a.#{@wiki_menu_item.menu_identifier}-menu-item.selected"
        end
      end

      describe "- wiki menu item pointing to a saved wiki page" do
        before do
          @wiki_menu_item = @main_menu_item_for_page_with_content
          @other_wiki_menu_item = @other_menu_item
        end

        it_behaves_like "all wiki menu items"
        it_behaves_like "all existing wiki menu items"
        it_behaves_like "all wiki menu items with child pages"
      end

      describe "- wiki menu item pointing to a new wiki page" do
        before do
          @wiki_menu_item = @main_menu_item_for_new_wiki_page
          @other_wiki_menu_item = @other_menu_item
        end

        it_behaves_like "all wiki menu items"
      end

      describe "- wiki_menu_item containing special chars only" do
        before do
          @wiki_menu_item = create(:wiki_menu_item,
                                   navigatable_id: project.wiki.id,
                                   title: "?",
                                   name: "help")
          @other_wiki_menu_item = @other_menu_item
        end

        it_behaves_like "all wiki menu items"
      end
    end

    describe "- wiki sidebar" do
      describe "configure menu items link" do
        describe "on a show page" do
          describe "being authorized to configure menu items" do
            it "is visible" do
              get "show", params: { project_id: project.id }

              expect(response).to be_successful

              assert_select "#content a", "Configure menu item"
            end
          end

          describe "being unauthorized to configure menu items" do
            before do
              allow(User).to receive(:current).and_return @anon
            end

            it "is invisible" do
              get "show", params: { project_id: project.id }

              expect(response).to be_successful

              assert_select "#content a", text: "Configure menu item", count: 0
            end
          end
        end
      end

      describe "new child page link" do
        describe "on an index page" do
          describe "being authorized to edit wiki pages" do
            it "is invisible" do
              get "index", params: { project_id: project.id }

              expect(response).to be_successful

              assert_select "#content a", text: "Wiki page", count: 0
            end
          end

          describe "being unauthorized to edit wiki pages" do
            before do
              allow(User).to receive(:current).and_return @anon
            end

            it "is invisible" do
              get "index", params: { project_id: project.id }

              expect(response).to be_successful

              assert_select "#content a", text: "Wiki page", count: 0
            end
          end
        end

        describe "on a wiki page" do
          describe "being authorized to edit wiki pages" do
            describe "with a wiki page present" do
              it "is visible" do
                get "show",
                    params: { id: page_with_content.title, project_id: project.identifier }

                expect(response).to be_successful

                # Expect to set back ref id
                expect(flash[:_related_wiki_page_id]).to eq page_with_content.id

                path = new_child_project_wiki_path(project_id: project, id: page_with_content.slug)

                assert_select "#content a[href='#{path}']", "Wiki page"
              end
            end

            describe "with no wiki page present" do
              it "is invisible" do
                get "show", params: { id: "i-am-a-ghostpage", project_id: project.identifier }

                expect(response).to be_successful

                assert_select "#content a[href='#{new_child_project_wiki_path(project_id: project, id: 'i-am-a-ghostpage')}']",
                              text: "Wiki page", count: 0
              end
            end
          end

          describe "being unauthorized to edit wiki pages" do
            before do
              allow(User).to receive(:current).and_return @anon
            end

            it "is invisible" do
              get "show", params: { id: page_with_content.title, project_id: project.identifier }

              expect(response).to be_successful

              assert_select "#content a", text: "Wiki page", count: 0
            end
          end
        end
      end

      describe "new page link" do
        describe "on a show page" do
          describe "being authorized to edit wiki pages" do
            it "is visible" do
              get "show", params: { project_id: project.id }

              expect(response).to be_successful

              assert_select ".toolbar-items a[href='#{new_child_project_wiki_path(project_id: project, id: 'wiki')}']",
                            "Wiki page"
            end
          end

          describe "being unauthorized to edit wiki pages" do
            before do
              allow(User).to receive(:current).and_return @anon
            end

            it "is invisible" do
              get "show", params: { project_id: project.id }

              expect(response).to be_successful

              assert_select ".toolbar-items a", text: "Wiki page", count: 0
            end
          end
        end
      end
    end
  end
end
