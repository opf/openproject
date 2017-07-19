#-- encoding: UTF-8

#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
require_relative '../legacy_spec_helper'
require 'wiki_controller'

describe WikiController, type: :controller do
  render_views

  fixtures :all

  before do
    User.current = nil
  end

  def wiki
    Project.first.wiki
  end

  def redirect_page
    wiki.find_page(wiki.start_page) || wiki.pages.first
  end

  it 'should show start page' do
    get :show, params: { project_id: 'ecookbook' }
    assert_response :success
    assert_template 'show'
    assert_select 'h1', content: /CookBook documentation/

    # child_pages macro
    assert_select 'ul', attributes: { class: 'pages-hierarchy' },
                    child: { tag: 'li',
                             child: { tag: 'a', attributes: { href: '/projects/ecookbook/wiki/Page_with_an_inline_image' },
                                      content: 'Page with an inline image' } }
  end

  it 'should show page with name' do
    get :show, params: { project_id: 1, id: 'Another page' }
    assert_response :success
    assert_template 'show'
    assert_select 'h1', content: /Another page/
    # Included page with an inline image
    assert_select 'p', content: /This is an inline image/
    assert_select 'img', attributes: { src: '/attachments/3/download',
                                         alt: 'This is a logo' }
  end

  it 'should show with sidebar' do
    page = Project.find(1).wiki.pages.new(title: 'Sidebar')
    page.content = WikiContent.new(text: 'Side bar content for test_show_with_sidebar')
    page.save!

    get :show, params: { project_id: 1, id: 'Another page' }
    assert_response :success
    assert_select 'div', attributes: { id: 'sidebar' },
               content: /Side bar content for test_show_with_sidebar/
  end

  it 'should show unexistent page without edit right' do
    get :show, params: { project_id: 1, id: 'Unexistent page' }
    assert_response 404
  end

  it 'should show unexistent page with edit right' do
    session[:user_id] = 2
    get :show, params: { project_id: 1, id: 'Unexistent page' }
    assert_response :success
    assert_template 'edit'
  end

  it 'should create page' do
    session[:user_id] = 2
    put :update, params: { project_id: 1,
                           id: 'New page',
                           content: { comments: 'Created the page',
                                      text: "h1. New page\n\nThis is a new page" } }
    assert_redirected_to action: 'show', project_id: 'ecookbook', id: 'new-page'
    page = wiki.find_page('New page')
    assert !page.new_record?
    refute_nil page.content
    assert_equal 'Created the page', page.content.last_journal.notes
  end

  it 'should create page with attachments' do
    session[:user_id] = 2
    assert_difference 'WikiPage.count' do
      assert_difference 'Attachment.count' do
        put :update, params: { project_id: 1,
                               id: 'New page',
                               content: { comments: 'Created the page',
                                          text: "h1. New page\n\nThis is a new page",
                                          lock_version: 0 },
                               attachments: { '1' => { 'file' => uploaded_test_file('testfile.txt', 'text/plain') } } }
      end
    end
    page = wiki.find_page('New page')
    assert_equal 1, page.attachments.count
    assert_equal 'testfile.txt', page.attachments.first.filename
  end

  it 'should update page' do
    page = Wiki.find(1).pages.find_by(title: 'Another page')
    page.content.recreate_initial_journal!

    session[:user_id] = 2
    assert_no_difference 'WikiPage.count' do
      assert_no_difference 'WikiContent.count' do
        assert_difference 'Journal.count' do
          put :update, params: { project_id: 1,
                                 id: 'Another page',
                                 content: {
                                   comments: 'my comments',
                                   text: 'edited',
                                   lock_version: 1
                                 } }
        end
      end
    end
    assert_redirected_to '/projects/ecookbook/wiki/another-page'

    page.reload
    assert_equal 'edited', page.content.text
    assert_equal page.content.journals.map(&:version).max, page.content.version
    assert_equal 'my comments', page.content.last_journal.notes
  end

  it 'should update page with failure' do
    session[:user_id] = 2
    assert_no_difference 'WikiPage.count' do
      assert_no_difference 'WikiContent.count' do
        assert_no_difference 'Journal.count' do
          put :update, params: { project_id: 1,
                                 id: 'Another page',
                                 content: {
                                   comments: 'a' * 300, # failure here, comment is too long
                                   text: 'edited',
                                   lock_version: 1
                                 } }
        end
      end
    end
    assert_response :success
    assert_template 'edit'

    assert_error_tag descendant: { content: /Comment is too long/ }
    assert_select 'textarea', attributes: { id: 'content_text' }, content: /edited/
    assert_select 'input', attributes: { id: 'content_lock_version', value: '1' }
  end

  # NOTE: this test seems to depend on other tests in suite
  # because running whole suite is fine, but running only this test
  # results in failure
  it 'should update stale page should not raise an error' do
    journal = FactoryGirl.create :wiki_content_journal,
                                 journable_id: 2,
                                 version: 1,
                                 data: FactoryGirl.build(:journal_wiki_content_journal,
                                                         text: "h1. Another page\n\n\nthis is a link to ticket: #2")
    session[:user_id] = 2
    c = Wiki.find(1).find_page('Another page').content
    c.text = 'Previous text'
    c.save!
    assert_equal 2, c.version

    assert_no_difference 'WikiPage.count' do
      assert_no_difference 'WikiContent.count' do
        assert_no_difference 'Journal.count' do
          put :update, params: { project_id: 1,
                                 id: 'Another page',
                                 content: {
                                   comments: 'My comments',
                                   text: 'Text should not be lost',
                                   lock_version: 1
                                 } }
        end
      end
    end
    assert_response :success
    assert_template 'edit'
    assert_select 'div',
                  attributes: { class: /error/ },
                  content: /Information has been updated by at least one other user in the meantime/
    assert_select 'textarea',
                  attributes: { name: 'content[text]' },
                  content: /Text should not be lost/
    assert_select 'input',
                  attributes: { name: 'content[comments]', value: 'My comments' }

    c.reload
    assert_equal 'Previous text', c.text
    assert_equal 2, c.version
  end

  it 'should history' do
    FactoryGirl.create :wiki_content_journal,
                       journable_id: 1,
                       data: FactoryGirl.build(:journal_wiki_content_journal,
                                               text: 'h1. CookBook documentation')
    FactoryGirl.create :wiki_content_journal,
                       journable_id: 1,
                       data: FactoryGirl.build(:journal_wiki_content_journal,
                                               text: "h1. CookBook documentation\n\n\nSome updated [[documentation]] here...")
    FactoryGirl.create :wiki_content_journal,
                       journable_id: 1,
                       data: FactoryGirl.build(:journal_wiki_content_journal,
                                               text: "h1. CookBook documentation\nSome updated [[documentation]] here...")

    get :history, params: { project_id: 1, id: 'CookBook documentation' }
    assert_response :success
    assert_template 'history'
    refute_nil assigns(:versions)
    assert_equal 3, assigns(:versions).size
    assert_select 'input[type=submit][name=commit]'
  end

  it 'should history with one version' do
    FactoryGirl.create :wiki_content_journal,
                       journable_id: 2,
                       data: FactoryGirl.build(:journal_wiki_content_journal,
                                               text: "h1. Another page\n\n\nthis is a link to ticket: #2")
    get :history, params: { project_id: 1, id: 'Another page' }
    assert_response :success
    assert_template 'history'
    refute_nil assigns(:versions)
    assert_equal 1, assigns(:versions).size
    assert_select 'input[type=submit][name=commit]', false
  end

  it 'should diff' do
    journal_from = FactoryGirl.create :wiki_content_journal,
                                      journable_id: 1,
                                      data: FactoryGirl.build(:journal_wiki_content_journal,
                                                              text: 'h1. CookBook documentation')
    journal_to = FactoryGirl.create :wiki_content_journal,
                                    journable_id: 1,
                                    data: FactoryGirl.build(:journal_wiki_content_journal,
                                                            text: "h1. CookBook documentation\n\n\nSome updated [[documentation]] here...")

    get :diff, params: { project_id: 1, id: 'CookBook documentation', version: journal_to.version, version_from: journal_from.version }
    assert_response :success
    assert_template 'diff'
    assert_select 'ins', attributes: { class: 'diffins' },
               content: /updated/
  end

  it 'should annotate' do
    FactoryGirl.create :wiki_content_journal,
                       journable_id: 1,
                       data: FactoryGirl.build(:journal_wiki_content_journal,
                                               text: 'h1. CookBook documentation')
    journal_to = FactoryGirl.create :wiki_content_journal,
                                    journable_id: 1,
                                    data: FactoryGirl.build(:journal_wiki_content_journal,
                                                            text: "h1. CookBook documentation\n\n\nSome [[documentation]] here...")

    get :annotate, params: { project_id: 1, id:  'CookBook documentation', version: journal_to.version }
    assert_response :success
    assert_template 'annotate'
    # Line 1
    assert_select 'tr', child: { tag: 'th', attributes: { class: 'line-num' }, content: '1' },
               child: { tag: 'td', attributes: { class: 'author' }, content: /John Smith/ },
               child: { tag: 'td', content: /h1\. CookBook documentation/ }
    # Line 2
    assert_select 'tr', child: { tag: 'th', attributes: { class: 'line-num' }, content: '2' },
               child: { tag: 'td', attributes: { class: 'author' }, content: /redMine Admin/ },
               child: { tag: 'td', content: /Some updated \[\[documentation\]\] here/ }
  end

  it 'should get rename' do
    session[:user_id] = 2
    get :rename, params: { project_id: 1, id: 'Another page' }
    assert_response :success
    assert_template 'rename'
  end

  it 'should get rename child page' do
    session[:user_id] = 2
    get :rename, params: { project_id: 1, id: 'Child 1' }
    assert_response :success
    assert_template 'rename'
  end

  it 'should rename with redirect' do
    session[:user_id] = 2
    patch :rename, params: { project_id: 1, id: 'Another page',
                             page: { title: 'Another renamed page',
                                     redirect_existing_links: 1 } }
    assert_redirected_to action: 'show', project_id: 'ecookbook', id: 'another-renamed-page'
    # Check redirects
    refute_nil wiki.find_page('Another page')
    assert_nil wiki.find_page('Another page', with_redirect: false)
  end

  it 'should rename without redirect' do
    session[:user_id] = 2
    patch :rename, params: { project_id: 1, id: 'another-page',
                             page: { title: 'Another renamed page',
                                     redirect_existing_links: '0' } }
    assert_redirected_to action: 'show', project_id: 'ecookbook', id: 'another-renamed-page'
    # Check that there's no redirects
    assert_nil wiki.find_page('Another page')
  end

  it 'should destroy child' do
    session[:user_id] = 2
    delete :destroy, params: { project_id: 1, id: 'Child 1' }
    assert_redirected_to action: 'index', project_id: 'ecookbook', id: redirect_page
  end

  it 'should destroy parent' do
    session[:user_id] = 2
    assert_no_difference('WikiPage.count') do
      delete :destroy, params: { project_id: 1, id: 'Another page' }
    end
    assert_response :success
    assert_template 'destroy'
  end

  it 'should destroy parent with nullify' do
    session[:user_id] = 2
    assert_difference('WikiPage.count', -1) do
      delete :destroy, params: { project_id: 1, id: 'Another page', todo: 'nullify' }
    end
    assert_redirected_to action: 'index', project_id: 'ecookbook', id: redirect_page
    assert_nil WikiPage.find_by(id: 2)
  end

  it 'should destroy parent with cascade' do
    session[:user_id] = 2
    assert_difference('WikiPage.count', -3) do
      delete :destroy, params: { project_id: 1, id: 'Another page', todo: 'destroy' }
    end
    assert_redirected_to action: 'index', project_id: 'ecookbook', id: redirect_page
    assert_nil WikiPage.find_by(id: 2)
    assert_nil WikiPage.find_by(id: 5)
  end

  it 'should destroy parent with reassign' do
    session[:user_id] = 2
    assert_difference('WikiPage.count', -1) do
      delete :destroy, params: { project_id: 1, id: 'Another page', todo: 'reassign', reassign_to_id: 1 }
    end
    assert_redirected_to action: 'index', project_id: 'ecookbook', id: redirect_page
    assert_nil WikiPage.find_by(id: 2)
    assert_equal WikiPage.find(1), WikiPage.find_by(id: 5).parent
  end

  it 'should index' do
    get :index, params: { project_id: 'ecookbook' }
    assert_response :success
    assert_template 'index'
    pages = assigns(:pages)
    refute_nil pages
    assert_equal wiki.pages.size, pages.size
    assert_equal pages.first.content.updated_on, pages.first.updated_on

    assert_select 'ul', attributes: { class: 'pages-hierarchy' },
                    child: { tag: 'li', child: { tag: 'a', attributes: { href: '/projects/ecookbook/wiki/CookBook%20documentation' },
                                                 content: 'CookBook documentation' },
                             child: { tag: 'ul',
                                      child: { tag: 'li',
                                               child: { tag: 'a', attributes: { href: '/projects/ecookbook/wiki/Page%20with%20an%20inline%20image' },
                                                        content: 'Page with an inline image' } } } },
                    child: { tag: 'li', child: { tag: 'a', attributes: { href: '/projects/ecookbook/wiki/Another%20page' },
                                                 content: 'Another page' } }
  end

  it 'should index should include atom link' do
    get :index, params: { project_id: 'ecookbook' }
    assert_select 'a', attributes: { href: '/projects/ecookbook/activity.atom?show_wiki_edits=1' }
  end

  context 'GET :export' do
    context 'with an authorized user to export the wiki' do
      before do
        session[:user_id] = 2
        get :export, params: { project_id: 'ecookbook' }
      end

      it { is_expected.to respond_with :success }
      it { should_assign_to :pages }
      it { should_respond_with_content_type 'text/html' }
      it 'should export all of the wiki pages to a single html file' do
        assert_select 'a[name=?]', 'cookbook-documentation'
        assert_select 'a[name=?]', 'another-page'
        assert_select 'a[name=?]', 'page-with-an-inline-image'
      end
    end

    context 'with an unauthorized user' do
      before do
        get :export, params: { project_id: 'ecookbook' }

        it { is_expected.to respond_with :redirect }
        it { is_expected.to redirect_to('wiki index') { { action: 'show', project_id: @project, id: nil } } }
      end
    end
  end

  context 'GET :date_index' do
    before do
      get :date_index, params: { project_id: 'ecookbook' }
    end

    it { is_expected.to respond_with :success }
    it { should_assign_to :pages }
    it { should_assign_to :pages_by_date }
    it { is_expected.to render_template 'wiki/date_index' }

    it 'should include atom link' do
      assert_select 'a', attributes: { href: '/projects/ecookbook/activity.atom?show_wiki_edits=1' }
    end
  end

  it 'should not found' do
    get :show, params: { project_id: 999 }
    assert_response 404
  end

  it 'should protect page' do
    page = WikiPage.find_by(wiki_id: 1, title: 'Another page')
    assert !page.protected?
    session[:user_id] = 2
    post :protect, params: { project_id: 1, id: page.title, protected: '1' }
    assert_redirected_to action: 'show', project_id: 'ecookbook', id: 'another-page'
    assert page.reload.protected?
  end

  it 'should unprotect page' do
    page = WikiPage.find_by(wiki_id: 1, title: 'CookBook documentation')
    assert page.protected?
    session[:user_id] = 2
    post :protect, params: { project_id: 1, id: page.title, protected: '0' }
    assert_redirected_to action: 'show', project_id: 'ecookbook', id: 'cookbook-documentation'
    assert !page.reload.protected?
  end

  it 'should show page with edit link' do
    session[:user_id] = 2
    get :show, params: { project_id: 1 }
    assert_response :success
    assert_template 'show'
    assert_select 'a', attributes: { href: '/projects/1/wiki/CookBook+documentation/edit' }
  end

  it 'should show page without edit link' do
    session[:user_id] = 4
    get :show, params: { project_id: 1 }
    assert_response :success
    assert_template 'show'
    assert_select('a', { attributes: { href: '/projects/1/wiki/CookBook+documentation/edit' } }, false)
  end

  it 'should edit unprotected page' do
    # Non members can edit unprotected wiki pages
    session[:user_id] = 4
    get :edit, params: { project_id: 1, id: 'Another page' }
    assert_response :success
    assert_template 'edit'
  end

  it 'should edit protected page by nonmember' do
    # Non members can't edit protected wiki pages
    session[:user_id] = 4
    get :edit, params: { project_id: 1, id: 'CookBook documentation' }
    assert_response 403
  end

  it 'should edit protected page by member' do
    session[:user_id] = 2
    get :edit, params: { project_id: 1, id: 'CookBook documentation' }
    assert_response :success
    assert_template 'edit'
  end

  it 'should history of non existing page should return 404' do
    get :history, params: { project_id: 1, id: 'Unknown page' }
    assert_response 404
  end
end
