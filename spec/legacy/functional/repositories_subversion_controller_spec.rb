#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
require 'legacy_spec_helper'
require 'repositories_controller'

describe RepositoriesController, 'Subversion', type: :controller do
  render_views

  fixtures :all

  PRJ_ID = 3

  before do
    skip 'Subversion test repository NOT FOUND. Skipping functional tests !!!' unless repository_configured?('subversion')

    Setting.default_language = 'en'
    User.current = nil

    @project = Project.find(PRJ_ID)
    @repository = Repository::Subversion.create(project: @project,
                                                url: self.class.subversion_repository_url)

    # #reload is broken for repositories because it defines
    # `has_many :changes` which conflicts with AR's #changes method
    # here we implement #reload differently for that single repository instance
    def @repository.reload
      ActiveRecord::Base.connection.clear_query_cache
      self.class.find(id)
    end

    assert @repository
  end

  it 'should show' do
    @repository.fetch_changesets
    @repository.reload
    get :show, project_id: PRJ_ID
    assert_response :success
    assert_template 'show'
    assert_not_nil assigns(:entries)
    assert_not_nil assigns(:changesets)
  end

  it 'should browse root' do
    @repository.fetch_changesets
    @repository.reload
    get :show, project_id: PRJ_ID
    assert_response :success
    assert_template 'show'
    assert_not_nil assigns(:entries)
    entry = assigns(:entries).detect { |e| e.name == 'subversion_test' }
    assert_equal 'dir', entry.kind
  end

  it 'should browse directory' do
    @repository.fetch_changesets
    @repository.reload
    get :show, project_id: PRJ_ID, path: 'subversion_test'
    assert_response :success
    assert_template 'show'
    assert_not_nil assigns(:entries)
    assert_equal ['[folder_with_brackets]', 'folder', '.project', 'helloworld.c', 'textfile.txt'], assigns(:entries).map(&:name)
    entry = assigns(:entries).detect { |e| e.name == 'helloworld.c' }
    assert_equal 'file', entry.kind
    assert_equal 'subversion_test/helloworld.c', entry.path
    assert_tag :a, content: 'helloworld.c', attributes: { class: /text\-x\-c/ }
  end

  it 'should browse at given revision' do
    @repository.fetch_changesets
    @repository.reload
    get :show, project_id: PRJ_ID, path: 'subversion_test', rev: 4
    assert_response :success
    assert_template 'show'
    assert_not_nil assigns(:entries)
    assert_equal ['folder', '.project', 'helloworld.c', 'helloworld.rb', 'textfile.txt'], assigns(:entries).map(&:name)
  end

  it 'should file changes' do
    @repository.fetch_changesets
    @repository.reload
    get :changes, project_id: PRJ_ID, path: 'subversion_test/folder/helloworld.rb'
    assert_response :success
    assert_template 'changes'

    changesets = assigns(:changesets)
    assert_not_nil changesets
    assert_equal %w(6 3 2), changesets.map(&:revision)

    # svn properties displayed with svn >= 1.5 only
    if Redmine::Scm::Adapters::SubversionAdapter.client_version_above?([1, 5, 0])
      assert_not_nil assigns(:properties)
      assert_equal 'native', assigns(:properties)['svn:eol-style']
      assert_tag :ul,
                 child: { tag: 'li',
                          child: { tag: 'b', content: 'svn:eol-style' },
                          child: { tag: 'span', content: 'native' } }
    end
  end

  it 'should directory changes' do
    @repository.fetch_changesets
    @repository.reload
    get :changes, project_id: PRJ_ID, path: 'subversion_test/folder'
    assert_response :success
    assert_template 'changes'

    changesets = assigns(:changesets)
    assert_not_nil changesets
    assert_equal %w(10 9 7 6 5 2), changesets.map(&:revision)
  end

  it 'should entry' do
    @repository.fetch_changesets
    @repository.reload
    get :entry, project_id: PRJ_ID, path: 'subversion_test/helloworld.c'
    assert_response :success
    assert_template 'entry'
  end

  it 'should entry should send if too big' do
    @repository.fetch_changesets
    @repository.reload
    # no files in the test repo is larger than 1KB...
    with_settings file_max_size_displayed: 0 do
      get :entry, project_id: PRJ_ID, path: 'subversion_test/helloworld.c'
      assert_response :success
      assert_template nil
      assert_equal 'attachment; filename="helloworld.c"', response.headers['Content-Disposition']
    end
  end

  it 'should entry at given revision' do
    @repository.fetch_changesets
    @repository.reload
    get :entry, project_id: PRJ_ID, path: 'subversion_test/helloworld.rb', rev: 2
    assert_response :success
    assert_template 'entry'
    # this line was removed in r3 and file was moved in r6
    assert_tag tag: 'td', attributes: { class: /line-code/ },
               content: /Here's the code/
  end

  it 'should entry not found' do
    @repository.fetch_changesets
    @repository.reload
    get :entry, project_id: PRJ_ID, path: 'subversion_test/zzz.c'
    assert_tag tag: 'div', attributes: { id: /errorExplanation/ },
               content: /The entry or revision was not found in the repository/
  end

  it 'should entry download' do
    @repository.fetch_changesets
    @repository.reload
    get :entry, project_id: PRJ_ID, path: 'subversion_test/helloworld.c', format: 'raw'
    assert_response :success
    assert_template nil
    assert_equal 'attachment; filename="helloworld.c"', response.headers['Content-Disposition']
  end

  it 'should directory entry' do
    @repository.fetch_changesets
    @repository.reload
    get :entry, project_id: PRJ_ID, path: 'subversion_test/folder'
    assert_response :success
    assert_template 'show'
    assert_not_nil assigns(:entry)
    assert_equal 'folder', assigns(:entry).name
  end

  # TODO: this test needs fixtures.
  it 'should revision' do
    @repository.fetch_changesets
    @repository.reload
    get :revision, project_id: 1, rev: 2
    assert_response :success
    assert_template 'revision'
    assert_tag tag: 'ul',
               child: { tag: 'li',
                        # link to the entry at rev 2
                        child: { tag: 'a',
                                 attributes: { href: '/projects/ecookbook/repository/revisions/2/entry/test/some/path/in/the/repo' },
                                 content: 'repo',
                                 # link to partial diff
                                 sibling:  { tag: 'a',
                                             attributes: { href: '/projects/ecookbook/repository/revisions/2/diff/test/some/path/in/the/repo' }
                                                     }
                                      }
                          }
  end

  it 'should invalid revision' do
    @repository.fetch_changesets
    @repository.reload
    get :revision, project_id: PRJ_ID, rev: 'something_weird'
    assert_response 404
    assert_error_tag content: /was not found/
  end

  it 'should invalid revision diff' do
    get :diff, project_id: PRJ_ID, rev: '1', rev_to: 'something_weird'
    assert_response 404
    assert_error_tag content: /was not found/
  end

  it 'should empty revision' do
    @repository.fetch_changesets
    @repository.reload
    ['', ' ', nil].each do |r|
      get :revision, project_id: PRJ_ID, rev: r
      assert_response 404
      assert_error_tag content: /was not found/
    end
  end

  # TODO: this test needs fixtures.
  it 'should revision with repository pointing to a subdirectory' do
    r = Project.find(1).repository
    # Changes repository url to a subdirectory
    r.update_attribute :url, (r.url + '/test/some')

    get :revision, project_id: 1, rev: 2
    assert_response :success
    assert_template 'revision'
    assert_tag tag: 'ul',
               child: { tag: 'li',
                        # link to the entry at rev 2
                        child: { tag: 'a',
                                 attributes: { href: '/projects/ecookbook/repository/revisions/2/entry/path/in/the/repo' },
                                 content: 'repo',
                                 # link to partial diff
                                 sibling:  { tag: 'a',
                                             attributes: { href: '/projects/ecookbook/repository/revisions/2/diff/path/in/the/repo' }
                                                     }
                                      }
                          }
  end

  it 'should revision diff' do
    @repository.fetch_changesets
    @repository.reload
    get :diff, project_id: PRJ_ID, rev: 3
    assert_response :success
    assert_template 'diff'

    assert_tag tag: 'h2', content: /3/
  end

  it 'should directory diff' do
    @repository.fetch_changesets
    @repository.reload
    get :diff, project_id: PRJ_ID, rev: 6, rev_to: 2, path: 'subversion_test/folder'
    assert_response :success
    assert_template 'diff'

    diff = assigns(:diff)
    assert_not_nil diff
    # 2 files modified
    assert_equal 2, Redmine::UnifiedDiff.new(diff).size

    assert_tag tag: 'h2', content: /2:6/
  end

  it 'should annotate' do
    @repository.fetch_changesets
    @repository.reload
    get :annotate, project_id: PRJ_ID, path: 'subversion_test/helloworld.c'
    assert_response :success
    assert_template 'annotate'
  end

  it 'should annotate at given revision' do
    @repository.fetch_changesets
    @repository.reload
    get :annotate, project_id: PRJ_ID, rev: 8, path: 'subversion_test/helloworld.c'
    assert_response :success
    assert_template 'annotate'
    assert_tag tag: 'h2', content: /@ 8/
  end
end
