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
require 'repositories_controller'

describe RepositoriesController, 'Git', type: :controller do
  render_views

  fixtures :all

  # No '..' in the repository path
  let(:git_repository_path) {
    path = Rails.root.to_s.gsub(%r{config\/\.\.}, '') + '/tmp/test/git_repository'
    path.gsub!(/\//, '\\') if Redmine::Platform.mswin?
    path
  }

  before do
    skip 'Git test repository NOT FOUND. Skipping functional tests !!!' unless File.directory?(git_repository_path)

    User.current = nil
    @repository = Repository::Git.create(
      project: Project.find(3),
      scm_type: 'local',
      url:     git_repository_path,
      path_encoding: 'ISO-8859-1'
    )

    # see repositories_subversion_controller_test.rb
    def @repository.reload
      ActiveRecord::Base.connection.clear_query_cache
      self.class.find(id)
    end

    assert @repository
  end

  it 'should browse root' do
    @repository.fetch_changesets
    @repository.reload
    get :show, params: { project_id: 3 }
    assert_response :success
    assert_template 'show'
    refute_nil assigns(:entries)
    assert_equal 10, assigns(:entries).size
    assert assigns(:entries).detect { |e| e.name == 'images' && e.kind == 'dir' }
    assert assigns(:entries).detect { |e| e.name == 'this_is_a_really_long_and_verbose_directory_name' && e.kind == 'dir' }
    assert assigns(:entries).detect { |e| e.name == 'sources' && e.kind == 'dir' }
    assert assigns(:entries).detect { |e| e.name == 'README' && e.kind == 'file' }
    assert assigns(:entries).detect { |e| e.name == 'copied_README' && e.kind == 'file' }
    assert assigns(:entries).detect { |e| e.name == 'new_file.txt' && e.kind == 'file' }
    assert assigns(:entries).detect { |e| e.name == 'renamed_test.txt' && e.kind == 'file' }
    assert assigns(:entries).detect { |e| e.name == 'filemane with spaces.txt' && e.kind == 'file' }
    assert assigns(:entries).detect { |e| e.name == ' filename with a leading space.txt ' && e.kind == 'file' }
    refute_nil assigns(:changesets)
    assigns(:changesets).size > 0
  end

  it 'should browse branch' do
    @repository.fetch_changesets
    @repository.reload
    get :show, params: { project_id: 3, rev: 'test_branch' }
    assert_response :success
    assert_template 'show'
    refute_nil assigns(:entries)
    assert_equal 4, assigns(:entries).size
    assert assigns(:entries).detect { |e| e.name == 'images' && e.kind == 'dir' }
    assert assigns(:entries).detect { |e| e.name == 'sources' && e.kind == 'dir' }
    assert assigns(:entries).detect { |e| e.name == 'README' && e.kind == 'file' }
    assert assigns(:entries).detect { |e| e.name == 'test.txt' && e.kind == 'file' }
    refute_nil assigns(:changesets)
    assigns(:changesets).size > 0
  end

  it 'should browse tag' do
    @repository.fetch_changesets
    @repository.reload
    [
      'tag00.lightweight',
      'tag01.annotated',
    ].each do |t1|
      get :show, params: { project_id: 3, rev: t1 }
      assert_response :success
      assert_template 'show'
      refute_nil assigns(:entries)
      assigns(:entries).size > 0
      refute_nil assigns(:changesets)
      assigns(:changesets).size > 0
    end
  end

  it 'should browse directory' do
    @repository.fetch_changesets
    @repository.reload
    get :show, params: { project_id: 3, path: 'images' }
    assert_response :success
    assert_template 'show'
    refute_nil assigns(:entries)
    assert_equal ['edit.png'], assigns(:entries).map(&:name)
    entry = assigns(:entries).detect { |e| e.name == 'edit.png' }
    refute_nil entry
    assert_equal 'file', entry.kind
    assert_equal 'images/edit.png', entry.path
    refute_nil assigns(:changesets)
    assigns(:changesets).size > 0
  end

  it 'should browse at given revision' do
    @repository.fetch_changesets
    @repository.reload
    get :show, params: { project_id: 3, path: 'images', rev: '7234cb2750b63f47bff735edc50a1c0a433c2518' }
    assert_response :success
    assert_template 'show'
    refute_nil assigns(:entries)
    assert_equal ['delete.png'], assigns(:entries).map(&:name)
    refute_nil assigns(:changesets)
    assigns(:changesets).size > 0
  end

  it 'should changes' do
    get :changes, params: { project_id: 3, path: 'images/edit.png' }
    assert_response :success
    assert_template 'changes'
    assert_select 'div',
               attributes: { class: 'repository-breadcrumbs' },
               content: 'edit.png'
  end

  it 'should entry show' do
    get :entry, params: { project_id: 3, path: 'sources/watchers_controller.rb' }
    assert_response :success
    assert_template 'entry'
    # Line 19
    assert_select 'th',
                  content: /11/,
                  attributes: { class: /line-num/ },
                  sibling: { tag: 'td', content: /WITHOUT ANY WARRANTY/ }
  end

  it 'should entry download' do
    get :entry, params: { project_id: 3, path: 'sources/watchers_controller.rb', format: 'raw' }
    assert_response :success
    # File content
    assert response.body.include?('WITHOUT ANY WARRANTY')
  end

  it 'should directory entry' do
    get :entry, params: { project_id: 3, path: 'sources' }
    assert_response :success
    assert_template 'show'
    refute_nil assigns(:entry)
    assert_equal 'sources', assigns(:entry).name
  end

  it 'should diff' do
    @repository.fetch_changesets
    @repository.reload

    # Full diff of changeset 2f9c0091
    get :diff, params: { project_id: 3, rev: '2f9c0091c754a91af7a9c478e36556b4bde8dcf7' }
    assert_response :success
    assert_template 'diff'
    # Line 22 removed
    assert_select 'th',
               content: /22/,
               sibling: { tag: 'td',
                          attributes: { class: /diff_out/ },
                          content: /def remove/ }
    assert_select 'h2', content: /2f9c0091/
  end

  it 'should diff two revs' do
    @repository.fetch_changesets
    @repository.reload

    get :diff, params: { project_id: 3, rev:    '61b685fbe55ab05b5ac68402d5720c1a6ac973d1',
                         rev_to: '2f9c0091c754a91af7a9c478e36556b4bde8dcf7' }
    assert_response :success
    assert_template 'diff'

    diff = assigns(:diff)
    refute_nil diff
    assert_select 'h2', content: /2f9c0091:61b685fb/
  end

  it 'should annotate' do
    get :annotate, params: { project_id: 3, path: 'sources/watchers_controller.rb' }
    assert_response :success
    assert_template 'annotate'
    # Line 23, changeset 2f9c0091
    assert_select 'th', content: /24/,
               sibling: { tag: 'td', child: { tag: 'a', content: /2f9c0091/ } },
               sibling: { tag: 'td', content: /jsmith/ },
               sibling: { tag: 'td', content: /watcher =/ }
  end

  it 'should annotate at given revision' do
    @repository.fetch_changesets
    @repository.reload
    get :annotate, params: { project_id: 3, rev: 'deff7', path: 'sources/watchers_controller.rb' }
    assert_response :success
    assert_template 'annotate'
    assert_select 'div',
               attributes: { class: 'repository-breadcrumbs' },
               content: /at deff712f/
  end

  it 'should annotate binary file' do
    get :annotate, params: { project_id: 3, path: 'images/edit.png' }
    assert_response 200

    assert_select 'p', attributes: { class: /nodata/ },
               content: I18n.t('repositories.warnings.cannot_annotate')
  end

  it 'should revision' do
    @repository.fetch_changesets
    @repository.reload
    ['61b685fbe55ab05b5ac68402d5720c1a6ac973d1', '61b685f'].each do |r|
      get :revision, params: { project_id: 3, rev: r }
      assert_response :success
      assert_template 'revision'
    end
  end

  it 'should empty revision' do
    @repository.fetch_changesets
    @repository.reload
    ['', ' ', nil].each do |r|
      get :revision, params: { project_id: 3, rev: r }
      assert_response 404
      assert_error_tag content: /was not found/
    end
  end
end
