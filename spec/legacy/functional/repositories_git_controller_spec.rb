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
    get :show, project_id: 3
    assert_response :success
    assert_template 'show'
    assert_not_nil assigns(:entries)
    assert_equal 9, assigns(:entries).size
    assert assigns(:entries).detect { |e| e.name == 'images' && e.kind == 'dir' }
    assert assigns(:entries).detect { |e| e.name == 'this_is_a_really_long_and_verbose_directory_name' && e.kind == 'dir' }
    assert assigns(:entries).detect { |e| e.name == 'sources' && e.kind == 'dir' }
    assert assigns(:entries).detect { |e| e.name == 'README' && e.kind == 'file' }
    assert assigns(:entries).detect { |e| e.name == 'copied_README' && e.kind == 'file' }
    assert assigns(:entries).detect { |e| e.name == 'new_file.txt' && e.kind == 'file' }
    assert assigns(:entries).detect { |e| e.name == 'renamed_test.txt' && e.kind == 'file' }
    assert assigns(:entries).detect { |e| e.name == 'filemane with spaces.txt' && e.kind == 'file' }
    assert assigns(:entries).detect { |e| e.name == ' filename with a leading space.txt ' && e.kind == 'file' }
    assert_not_nil assigns(:changesets)
    assigns(:changesets).size > 0
  end

  it 'should browse branch' do
    @repository.fetch_changesets
    @repository.reload
    get :show, project_id: 3, rev: 'test_branch'
    assert_response :success
    assert_template 'show'
    assert_not_nil assigns(:entries)
    assert_equal 4, assigns(:entries).size
    assert assigns(:entries).detect { |e| e.name == 'images' && e.kind == 'dir' }
    assert assigns(:entries).detect { |e| e.name == 'sources' && e.kind == 'dir' }
    assert assigns(:entries).detect { |e| e.name == 'README' && e.kind == 'file' }
    assert assigns(:entries).detect { |e| e.name == 'test.txt' && e.kind == 'file' }
    assert_not_nil assigns(:changesets)
    assigns(:changesets).size > 0
  end

  it 'should browse tag' do
    @repository.fetch_changesets
    @repository.reload
    [
      'tag00.lightweight',
      'tag01.annotated',
    ].each do |t1|
      get :show, project_id: 3, rev: t1
      assert_response :success
      assert_template 'show'
      assert_not_nil assigns(:entries)
      assigns(:entries).size > 0
      assert_not_nil assigns(:changesets)
      assigns(:changesets).size > 0
    end
  end

  it 'should browse directory' do
    @repository.fetch_changesets
    @repository.reload
    get :show, project_id: 3, path: 'images'
    assert_response :success
    assert_template 'show'
    assert_not_nil assigns(:entries)
    assert_equal ['edit.png'], assigns(:entries).map(&:name)
    entry = assigns(:entries).detect { |e| e.name == 'edit.png' }
    assert_not_nil entry
    assert_equal 'file', entry.kind
    assert_equal 'images/edit.png', entry.path
    assert_not_nil assigns(:changesets)
    assigns(:changesets).size > 0
  end

  it 'should browse at given revision' do
    @repository.fetch_changesets
    @repository.reload
    get :show, project_id: 3, path: 'images', rev: '7234cb2750b63f47bff735edc50a1c0a433c2518'
    assert_response :success
    assert_template 'show'
    assert_not_nil assigns(:entries)
    assert_equal ['delete.png'], assigns(:entries).map(&:name)
    assert_not_nil assigns(:changesets)
    assigns(:changesets).size > 0
  end

  it 'should changes' do
    get :changes, project_id: 3, path: 'images/edit.png'
    assert_response :success
    assert_template 'changes'
    assert_tag tag: 'h2', content: 'edit.png'
  end

  it 'should entry show' do
    get :entry, project_id: 3, path: 'sources/watchers_controller.rb'
    assert_response :success
    assert_template 'entry'
    # Line 19
    assert_tag tag: 'th',
               content: /11/,
               attributes: { class: /line-num/ },
               sibling: { tag: 'td', content: /WITHOUT ANY WARRANTY/ }
  end

  it 'should entry download' do
    get :entry, project_id: 3, path: 'sources/watchers_controller.rb', format: 'raw'
    assert_response :success
    # File content
    assert response.body.include?('WITHOUT ANY WARRANTY')
  end

  it 'should directory entry' do
    get :entry, project_id: 3, path: 'sources'
    assert_response :success
    assert_template 'show'
    assert_not_nil assigns(:entry)
    assert_equal 'sources', assigns(:entry).name
  end

  it 'should diff' do
    @repository.fetch_changesets
    @repository.reload

    # Full diff of changeset 2f9c0091
    get :diff, project_id: 3, rev: '2f9c0091c754a91af7a9c478e36556b4bde8dcf7'
    assert_response :success
    assert_template 'diff'
    # Line 22 removed
    assert_tag tag: 'th',
               content: /22/,
               sibling: { tag: 'td',
                          attributes: { class: /diff_out/ },
                          content: /def remove/ }
    assert_tag tag: 'h2', content: /2f9c0091/
  end

  it 'should diff two revs' do
    @repository.fetch_changesets
    @repository.reload

    get :diff, project_id: 3, rev:    '61b685fbe55ab05b5ac68402d5720c1a6ac973d1',
               rev_to: '2f9c0091c754a91af7a9c478e36556b4bde8dcf7'
    assert_response :success
    assert_template 'diff'

    diff = assigns(:diff)
    assert_not_nil diff
    assert_tag tag: 'h2', content: /2f9c0091:61b685fb/
  end

  it 'should annotate' do
    get :annotate, project_id: 3, path: 'sources/watchers_controller.rb'
    assert_response :success
    assert_template 'annotate'
    # Line 23, changeset 2f9c0091
    assert_tag tag: 'th', content: /24/,
               sibling: { tag: 'td', child: { tag: 'a', content: /2f9c0091/ } },
               sibling: { tag: 'td', content: /jsmith/ },
               sibling: { tag: 'td', content: /watcher =/ }
  end

  it 'should annotate at given revision' do
    @repository.fetch_changesets
    @repository.reload
    get :annotate, project_id: 3, rev: 'deff7', path: 'sources/watchers_controller.rb'
    assert_response :success
    assert_template 'annotate'
    assert_tag tag: 'h2', content: /@ deff712f/
  end

  it 'should annotate binary file' do
    get :annotate, project_id: 3, path: 'images/edit.png'
    assert_response 500
    assert_tag tag: 'div', attributes: { id: /errorExplanation/ },
               content: /cannot be annotated/
  end

  it 'should revision' do
    @repository.fetch_changesets
    @repository.reload
    ['61b685fbe55ab05b5ac68402d5720c1a6ac973d1', '61b685f'].each do |r|
      get :revision, project_id: 3, rev: r
      assert_response :success
      assert_template 'revision'
    end
  end

  it 'should empty revision' do
    @repository.fetch_changesets
    @repository.reload
    ['', ' ', nil].each do |r|
      get :revision, project_id: 3, rev: r
      assert_response 404
      assert_error_tag content: /was not found/
    end
  end
end
