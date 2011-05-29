#-- copyright
# ChiliProject is a project management system.
# 
# Copyright (C) 2010-2011 the ChiliProject Team
# 
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
# 
# See doc/COPYRIGHT.rdoc for more details.
#++
require File.expand_path('../../test_helper', __FILE__)

class RepositoryGitTest < ActiveSupport::TestCase
  fixtures :projects, :repositories, :enabled_modules, :users, :roles

  # No '..' in the repository path
  REPOSITORY_PATH = RAILS_ROOT.gsub(%r{config\/\.\.}, '') + '/tmp/test/git_repository'
  REPOSITORY_PATH.gsub!(/\//, "\\") if Redmine::Platform.mswin?

  FELIX_HEX  = "Felix Sch\xC3\xA4fer"
  CHAR_1_HEX = "\xc3\x9c"

  ## Ruby uses ANSI api to fork a process on Windows.
  ## Japanese Shift_JIS and Traditional Chinese Big5 have 0x5c(backslash) problem
  ## and these are incompatible with ASCII.
  # WINDOWS_PASS = Redmine::Platform.mswin?
  WINDOWS_PASS = false

  def setup
    @project = Project.find(3)
    @repository = Repository::Git.create(
                      :project       => @project,
                      :url           => REPOSITORY_PATH,
                      :path_encoding => 'ISO-8859-1'
                      )
    assert @repository
    @char_1        = CHAR_1_HEX.dup
    if @char_1.respond_to?(:force_encoding)
      @char_1.force_encoding('UTF-8')
    end
  end

  if File.directory?(REPOSITORY_PATH)
    def test_fetch_changesets_from_scratch
      @repository.fetch_changesets
      @repository.reload

      assert_equal 21, @repository.changesets.count
      assert_equal 33, @repository.changes.count

      commit = @repository.changesets.find(:first, :order => 'committed_on ASC')
      assert_equal "Initial import.\nThe repository contains 3 files.", commit.comments
      assert_equal "jsmith <jsmith@foo.bar>", commit.committer
      assert_equal User.find_by_login('jsmith'), commit.user
      # TODO: add a commit with commit time <> author time to the test repository
      assert_equal "2007-12-14 09:22:52".to_time, commit.committed_on
      assert_equal "2007-12-14".to_date, commit.commit_date
      assert_equal "7234cb2750b63f47bff735edc50a1c0a433c2518", commit.revision
      assert_equal "7234cb2750b63f47bff735edc50a1c0a433c2518", commit.scmid
      assert_equal 3, commit.changes.count
      change = commit.changes.sort_by(&:path).first
      assert_equal "README", change.path
      assert_equal "A", change.action
    end
    
    def test_fetch_changesets_incremental
      @repository.fetch_changesets
      # Remove the 3 latest changesets
      @repository.changesets.find(:all, :order => 'committed_on DESC', :limit => 8).each(&:destroy)
      @repository.reload
      cs1 = @repository.changesets
      assert_equal 13, cs1.count

      rev_a_commit = @repository.changesets.find(:first, :order => 'committed_on DESC')
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

    def test_latest_changesets
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
          ], changesets.collect(&:revision)

      changesets = @repository.latest_changesets('README', nil)
      assert_equal [
              '32ae898b720c2f7eec2723d5bdd558b4cb2d3ddf',
              '4a07fe31bffcf2888791f3e6cbc9c4545cefe3e8',
              '713f4944648826f558cf548222f813dabe7cbb04',
              '61b685fbe55ab05b5ac68402d5720c1a6ac973d1',
              '899a15dba03a3b350b89c3f537e4bbe02a03cdc9',
              '7234cb2750b63f47bff735edc50a1c0a433c2518',
          ], changesets.collect(&:revision)

      # with path, revision and limit
      changesets = @repository.latest_changesets('images', '899a15dba')
      assert_equal [
              '899a15dba03a3b350b89c3f537e4bbe02a03cdc9',
              '7234cb2750b63f47bff735edc50a1c0a433c2518',
          ], changesets.collect(&:revision)

      changesets = @repository.latest_changesets('images', '899a15dba', 1)
      assert_equal [
              '899a15dba03a3b350b89c3f537e4bbe02a03cdc9',
          ], changesets.collect(&:revision)

      changesets = @repository.latest_changesets('README', '899a15dba')
      assert_equal [
              '899a15dba03a3b350b89c3f537e4bbe02a03cdc9',
              '7234cb2750b63f47bff735edc50a1c0a433c2518',
          ], changesets.collect(&:revision)

      changesets = @repository.latest_changesets('README', '899a15dba', 1)
      assert_equal [
              '899a15dba03a3b350b89c3f537e4bbe02a03cdc9',
          ], changesets.collect(&:revision)

      # with path, tag and limit
      changesets = @repository.latest_changesets('images', 'tag01.annotated')
      assert_equal [
              '899a15dba03a3b350b89c3f537e4bbe02a03cdc9',
              '7234cb2750b63f47bff735edc50a1c0a433c2518',
          ], changesets.collect(&:revision)

      changesets = @repository.latest_changesets('images', 'tag01.annotated', 1)
      assert_equal [
              '899a15dba03a3b350b89c3f537e4bbe02a03cdc9',
          ], changesets.collect(&:revision)

      changesets = @repository.latest_changesets('README', 'tag01.annotated')
      assert_equal [
              '899a15dba03a3b350b89c3f537e4bbe02a03cdc9',
              '7234cb2750b63f47bff735edc50a1c0a433c2518',
          ], changesets.collect(&:revision)

      changesets = @repository.latest_changesets('README', 'tag01.annotated', 1)
      assert_equal [
              '899a15dba03a3b350b89c3f537e4bbe02a03cdc9',
          ], changesets.collect(&:revision)

      # with path, branch and limit
      changesets = @repository.latest_changesets('images', 'test_branch')
      assert_equal [
              '899a15dba03a3b350b89c3f537e4bbe02a03cdc9',
              '7234cb2750b63f47bff735edc50a1c0a433c2518',
          ], changesets.collect(&:revision)

      changesets = @repository.latest_changesets('images', 'test_branch', 1)
      assert_equal [
              '899a15dba03a3b350b89c3f537e4bbe02a03cdc9',
          ], changesets.collect(&:revision)

      changesets = @repository.latest_changesets('README', 'test_branch')
      assert_equal [
              '713f4944648826f558cf548222f813dabe7cbb04',
              '61b685fbe55ab05b5ac68402d5720c1a6ac973d1',
              '899a15dba03a3b350b89c3f537e4bbe02a03cdc9',
              '7234cb2750b63f47bff735edc50a1c0a433c2518',
          ], changesets.collect(&:revision)

      changesets = @repository.latest_changesets('README', 'test_branch', 2)
      assert_equal [
              '713f4944648826f558cf548222f813dabe7cbb04',
              '61b685fbe55ab05b5ac68402d5720c1a6ac973d1',
          ], changesets.collect(&:revision)

      # latin-1 encoding path
      changesets = @repository.latest_changesets(
                    "latin-1-dir/test-#{@char_1}-2.txt", '64f1f3e89')
      assert_equal [
              '64f1f3e89ad1cb57976ff0ad99a107012ba3481d',
              '4fc55c43bf3d3dc2efb66145365ddc17639ce81e',
          ], changesets.collect(&:revision)

      changesets = @repository.latest_changesets(
                    "latin-1-dir/test-#{@char_1}-2.txt", '64f1f3e89', 1)
      assert_equal [
              '64f1f3e89ad1cb57976ff0ad99a107012ba3481d',
          ], changesets.collect(&:revision)
    end

    def test_latest_changesets_latin_1_dir
      if WINDOWS_PASS
        #
      else
        @repository.fetch_changesets
        @repository.reload
        changesets = @repository.latest_changesets(
                    "latin-1-dir/test-#{@char_1}-subdir", '1ca7f5ed')
        assert_equal [
              '1ca7f5ed374f3cb31a93ae5215c2e25cc6ec5127',
          ], changesets.collect(&:revision)
      end
    end

    def test_find_changeset_by_name
      @repository.fetch_changesets
      @repository.reload
      ['7234cb2750b63f47bff735edc50a1c0a433c2518', '7234cb2750b'].each do |r|
        assert_equal '7234cb2750b63f47bff735edc50a1c0a433c2518',
                     @repository.find_changeset_by_name(r).revision
      end
    end

    def test_find_changeset_by_empty_name
      @repository.fetch_changesets
      @repository.reload
      ['', ' ', nil].each do |r|
        assert_nil @repository.find_changeset_by_name(r)
      end
    end

    def test_identifier
      @repository.fetch_changesets
      @repository.reload
      c = @repository.changesets.find_by_revision('7234cb2750b63f47bff735edc50a1c0a433c2518')
      assert_equal c.scmid, c.identifier
    end

    def test_format_identifier
      @repository.fetch_changesets
      @repository.reload
      c = @repository.changesets.find_by_revision('7234cb2750b63f47bff735edc50a1c0a433c2518')
      assert_equal '7234cb27', c.format_identifier
    end

    def test_activities
      c = Changeset.create(:repository => @repository,
                        :committed_on => Time.now,
                        :revision => 'abc7234cb2750b63f47bff735edc50a1c0a433c2',
                        :scmid    => 'abc7234cb2750b63f47bff735edc50a1c0a433c2',
                        :comments => 'test')
      assert c.event_title.include?('abc7234c:')
      assert_equal 'abc7234cb2750b63f47bff735edc50a1c0a433c2', c.event_url[:rev]
    end

    def test_log_utf8
      @repository.fetch_changesets
      @repository.reload
      str_felix_hex  = FELIX_HEX.dup
      if str_felix_hex.respond_to?(:force_encoding)
          str_felix_hex.force_encoding('UTF-8')
      end
      c = @repository.changesets.find_by_revision('ed5bb786bbda2dee66a2d50faf51429dbc043a7b')
      assert_equal "#{str_felix_hex} <felix@fachschaften.org>", c.committer
    end

    def test_previous
      @repository.fetch_changesets
      @repository.reload
      %w|1ca7f5ed374f3cb31a93ae5215c2e25cc6ec5127 1ca7f5ed|.each do |r1|
        changeset = @repository.find_changeset_by_name(r1)
        %w|64f1f3e89ad1cb57976ff0ad99a107012ba3481d 64f1f3e89ad1|.each do |r2|
          assert_equal @repository.find_changeset_by_name(r2), changeset.previous
        end
      end
    end

    def test_previous_nil
      @repository.fetch_changesets
      @repository.reload
      %w|7234cb2750b63f47bff735edc50a1c0a433c2518 7234cb2|.each do |r1|
        changeset = @repository.find_changeset_by_name(r1)
        assert_nil changeset.previous
      end
    end

    def test_next
      @repository.fetch_changesets
      @repository.reload
      %w|64f1f3e89ad1cb57976ff0ad99a107012ba3481d 64f1f3e89ad1|.each do |r2|
        changeset = @repository.find_changeset_by_name(r2)
        %w|1ca7f5ed374f3cb31a93ae5215c2e25cc6ec5127 1ca7f5ed|.each do |r1|
        assert_equal @repository.find_changeset_by_name(r1), changeset.next
        end
      end
    end

    def test_next_nil
      @repository.fetch_changesets
      @repository.reload
      %w|1ca7f5ed374f3cb31a93ae5215c2e25cc6ec5127 1ca7f5ed|.each do |r1|
        changeset = @repository.find_changeset_by_name(r1)
        assert_nil changeset.next
      end
    end
  else
    puts "Git test repository NOT FOUND. Skipping unit tests !!!"
    def test_fake; assert true end
  end
end
