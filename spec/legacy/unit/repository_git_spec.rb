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

describe Repository::Git, type: :model do
  fixtures :all

  # No '..' in the repository path
  let(:git_repository_path) {
    path = Rails.root.to_s.gsub(%r{config\/\.\.}, '') + '/tmp/test/git_repository'
    path.gsub!(/\//, '\\') if Redmine::Platform.mswin?
    path
  }

  FELIX_HEX  = "Felix Sch\xC3\xA4fer"
  CHAR_1_HEX = "\xc3\x9c"

  ## Ruby uses ANSI api to fork a process on Windows.
  ## Japanese Shift_JIS and Traditional Chinese Big5 have 0x5c(backslash) problem
  ## and these are incompatible with ASCII.
  # WINDOWS_PASS = Redmine::Platform.mswin?
  WINDOWS_PASS = false

  before do
    skip 'Git test repository NOT FOUND. Skipping unit tests !!!' unless File.directory?(git_repository_path)

    @project = Project.find(3)
    @repository = Repository::Git.create(
      project:       @project,
      url:           git_repository_path,
      path_encoding: 'ISO-8859-1'
    )
    assert @repository
    @char_1        = CHAR_1_HEX.dup
    if @char_1.respond_to?(:force_encoding)
      @char_1.force_encoding('UTF-8')
    end
  end

  it 'should fetch changesets from scratch' do
    @repository.fetch_changesets
    @repository.reload

    assert_equal 21, @repository.changesets.count
    assert_equal 33, @repository.changes.count

    commit = @repository.changesets.reorder('committed_on ASC').first
    assert_equal "Initial import.\nThe repository contains 3 files.", commit.comments
    assert_equal 'jsmith <jsmith@foo.bar>', commit.committer
    assert_equal User.find_by_login('jsmith'), commit.user
    # TODO: add a commit with commit time <> author time to the test repository
    assert_equal '2007-12-14 09:22:52'.to_time, commit.committed_on
    assert_equal '2007-12-14'.to_date, commit.commit_date
    assert_equal '7234cb2750b63f47bff735edc50a1c0a433c2518', commit.revision
    assert_equal '7234cb2750b63f47bff735edc50a1c0a433c2518', commit.scmid
    assert_equal 3, commit.changes.count
    change = commit.changes.sort_by(&:path).first
    assert_equal 'README', change.path
    assert_equal 'A', change.action
  end

  it 'should fetch changesets incremental' do
    @repository.fetch_changesets
    # Remove the 3 latest changesets
    @repository.changesets.find(:all, order: 'committed_on DESC', limit: 8).each(&:destroy)
    @repository.reload
    cs1 = @repository.changesets
    assert_equal 13, cs1.count

    rev_a_commit = @repository.changesets.find(:first, order: 'committed_on DESC')
    assert_equal '4f26664364207fa8b1af9f8722647ab2d4ac5d43', rev_a_commit.revision
    # Mon Jul 5 22:34:26 2010 +0200
    rev_a_committed_on = Time.gm(2010, 7, 5, 20, 34, 26)
    assert_equal '4f26664364207fa8b1af9f8722647ab2d4ac5d43', rev_a_commit.scmid
    assert_equal rev_a_committed_on, rev_a_commit.committed_on
    latest_rev = @repository.latest_changeset
    assert_equal rev_a_committed_on, latest_rev.committed_on

    @repository.fetch_changesets
    assert_equal 21, @repository.changesets.count
  end

  it 'should latest changesets' do
    @repository.fetch_changesets
    @repository.reload
    # with limit
    changesets = @repository.latest_changesets('', nil, 2)
    assert_equal 2, changesets.size

    # with path
    changesets = @repository.latest_changesets('images', nil)
    assert_equal [
      'deff712f05a90d96edbd70facc47d944be5897e3',
      '899a15dba03a3b350b89c3f537e4bbe02a03cdc9',
      '7234cb2750b63f47bff735edc50a1c0a433c2518',
    ], changesets.map(&:revision)

    changesets = @repository.latest_changesets('README', nil)
    assert_equal [
      '32ae898b720c2f7eec2723d5bdd558b4cb2d3ddf',
      '4a07fe31bffcf2888791f3e6cbc9c4545cefe3e8',
      '713f4944648826f558cf548222f813dabe7cbb04',
      '61b685fbe55ab05b5ac68402d5720c1a6ac973d1',
      '899a15dba03a3b350b89c3f537e4bbe02a03cdc9',
      '7234cb2750b63f47bff735edc50a1c0a433c2518',
    ], changesets.map(&:revision)

    # with path, revision and limit
    changesets = @repository.latest_changesets('images', '899a15dba')
    assert_equal [
      '899a15dba03a3b350b89c3f537e4bbe02a03cdc9',
      '7234cb2750b63f47bff735edc50a1c0a433c2518',
    ], changesets.map(&:revision)

    changesets = @repository.latest_changesets('images', '899a15dba', 1)
    assert_equal [
      '899a15dba03a3b350b89c3f537e4bbe02a03cdc9',
    ], changesets.map(&:revision)

    changesets = @repository.latest_changesets('README', '899a15dba')
    assert_equal [
      '899a15dba03a3b350b89c3f537e4bbe02a03cdc9',
      '7234cb2750b63f47bff735edc50a1c0a433c2518',
    ], changesets.map(&:revision)

    changesets = @repository.latest_changesets('README', '899a15dba', 1)
    assert_equal [
      '899a15dba03a3b350b89c3f537e4bbe02a03cdc9',
    ], changesets.map(&:revision)

    # with path, tag and limit
    changesets = @repository.latest_changesets('images', 'tag01.annotated')
    assert_equal [
      '899a15dba03a3b350b89c3f537e4bbe02a03cdc9',
      '7234cb2750b63f47bff735edc50a1c0a433c2518',
    ], changesets.map(&:revision)

    changesets = @repository.latest_changesets('images', 'tag01.annotated', 1)
    assert_equal [
      '899a15dba03a3b350b89c3f537e4bbe02a03cdc9',
    ], changesets.map(&:revision)

    changesets = @repository.latest_changesets('README', 'tag01.annotated')
    assert_equal [
      '899a15dba03a3b350b89c3f537e4bbe02a03cdc9',
      '7234cb2750b63f47bff735edc50a1c0a433c2518',
    ], changesets.map(&:revision)

    changesets = @repository.latest_changesets('README', 'tag01.annotated', 1)
    assert_equal [
      '899a15dba03a3b350b89c3f537e4bbe02a03cdc9',
    ], changesets.map(&:revision)

    # with path, branch and limit
    changesets = @repository.latest_changesets('images', 'test_branch')
    assert_equal [
      '899a15dba03a3b350b89c3f537e4bbe02a03cdc9',
      '7234cb2750b63f47bff735edc50a1c0a433c2518',
    ], changesets.map(&:revision)

    changesets = @repository.latest_changesets('images', 'test_branch', 1)
    assert_equal [
      '899a15dba03a3b350b89c3f537e4bbe02a03cdc9',
    ], changesets.map(&:revision)

    changesets = @repository.latest_changesets('README', 'test_branch')
    assert_equal [
      '713f4944648826f558cf548222f813dabe7cbb04',
      '61b685fbe55ab05b5ac68402d5720c1a6ac973d1',
      '899a15dba03a3b350b89c3f537e4bbe02a03cdc9',
      '7234cb2750b63f47bff735edc50a1c0a433c2518',
    ], changesets.map(&:revision)

    changesets = @repository.latest_changesets('README', 'test_branch', 2)
    assert_equal [
      '713f4944648826f558cf548222f813dabe7cbb04',
      '61b685fbe55ab05b5ac68402d5720c1a6ac973d1',
    ], changesets.map(&:revision)

    # latin-1 encoding path
    changesets = @repository.latest_changesets(
      "latin-1-dir/test-#{@char_1}-2.txt", '64f1f3e89')
    assert_equal [
      '64f1f3e89ad1cb57976ff0ad99a107012ba3481d',
      '4fc55c43bf3d3dc2efb66145365ddc17639ce81e',
    ], changesets.map(&:revision)

    changesets = @repository.latest_changesets(
      "latin-1-dir/test-#{@char_1}-2.txt", '64f1f3e89', 1)
    assert_equal [
      '64f1f3e89ad1cb57976ff0ad99a107012ba3481d',
    ], changesets.map(&:revision)
  end

  it 'should latest changesets latin 1 dir' do
    if WINDOWS_PASS
      #
    else
      @repository.fetch_changesets
      @repository.reload
      changesets = @repository.latest_changesets(
        "latin-1-dir/test-#{@char_1}-subdir", '1ca7f5ed')
      assert_equal [
        '1ca7f5ed374f3cb31a93ae5215c2e25cc6ec5127',
      ], changesets.map(&:revision)
    end
  end

  it 'should find changeset by name' do
    @repository.fetch_changesets
    @repository.reload
    ['7234cb2750b63f47bff735edc50a1c0a433c2518', '7234cb2750b'].each do |r|
      assert_equal '7234cb2750b63f47bff735edc50a1c0a433c2518',
                   @repository.find_changeset_by_name(r).revision
    end
  end

  it 'should find changeset by empty name' do
    @repository.fetch_changesets
    @repository.reload
    ['', ' ', nil].each do |r|
      assert_nil @repository.find_changeset_by_name(r)
    end
  end

  it 'should identifier' do
    @repository.fetch_changesets
    @repository.reload
    c = @repository.changesets.find_by_revision('7234cb2750b63f47bff735edc50a1c0a433c2518')
    assert_equal c.scmid, c.identifier
  end

  it 'should format identifier' do
    @repository.fetch_changesets
    @repository.reload
    c = @repository.changesets.find_by_revision('7234cb2750b63f47bff735edc50a1c0a433c2518')
    assert_equal '7234cb27', c.format_identifier
  end

  it 'should activities' do
    c = Changeset.create(repository: @repository,
                         committed_on: Time.now,
                         revision: 'abc7234cb2750b63f47bff735edc50a1c0a433c2',
                         scmid:    'abc7234cb2750b63f47bff735edc50a1c0a433c2',
                         comments: 'test')

    event = find_events(User.find(2)).first # manager
    assert event.event_title.include?('abc7234c:')
    assert event.event_path =~ /\?rev=abc7234cb2750b63f47bff735edc50a1c0a433c2$/
  end

  it 'should log utf8' do
    @repository.fetch_changesets
    @repository.reload
    str_felix_hex  = FELIX_HEX.dup
    if str_felix_hex.respond_to?(:force_encoding)
      str_felix_hex.force_encoding('UTF-8')
    end
    c = @repository.changesets.find_by_revision('ed5bb786bbda2dee66a2d50faf51429dbc043a7b')
    assert_equal "#{str_felix_hex} <felix@fachschaften.org>", c.committer
  end

  it 'should previous' do
    @repository.fetch_changesets
    @repository.reload
    %w|1ca7f5ed374f3cb31a93ae5215c2e25cc6ec5127 1ca7f5ed|.each do |r1|
      changeset = @repository.find_changeset_by_name(r1)
      %w|64f1f3e89ad1cb57976ff0ad99a107012ba3481d 64f1f3e89ad1|.each do |r2|
        assert_equal @repository.find_changeset_by_name(r2), changeset.previous
      end
    end
  end

  it 'should previous nil' do
    @repository.fetch_changesets
    @repository.reload
    %w|7234cb2750b63f47bff735edc50a1c0a433c2518 7234cb2|.each do |r1|
      changeset = @repository.find_changeset_by_name(r1)
      assert_nil changeset.previous
    end
  end

  it 'should next' do
    @repository.fetch_changesets
    @repository.reload
    %w|64f1f3e89ad1cb57976ff0ad99a107012ba3481d 64f1f3e89ad1|.each do |r2|
      changeset = @repository.find_changeset_by_name(r2)
      %w|1ca7f5ed374f3cb31a93ae5215c2e25cc6ec5127 1ca7f5ed|.each do |r1|
        assert_equal @repository.find_changeset_by_name(r1), changeset.next
      end
    end
  end

  it 'should next nil' do
    @repository.fetch_changesets
    @repository.reload
    %w|1ca7f5ed374f3cb31a93ae5215c2e25cc6ec5127 1ca7f5ed|.each do |r1|
      changeset = @repository.find_changeset_by_name(r1)
      assert_nil changeset.next
    end
  end

  private

  def find_events(user, options = {})
    fetcher = Redmine::Activity::Fetcher.new(user, options)
    fetcher.scope = ['changesets']
    fetcher.events(Date.today - 30, Date.today + 1)
  end
end
