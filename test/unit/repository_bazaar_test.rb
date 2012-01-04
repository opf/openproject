#-- encoding: UTF-8
#-- copyright
# ChiliProject is a project management system.
#
# Copyright (C) 2010-2012 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# See doc/COPYRIGHT.rdoc for more details.
#++
require File.expand_path('../../test_helper', __FILE__)

class RepositoryBazaarTest < ActiveSupport::TestCase
  fixtures :projects

  # No '..' in the repository path
  REPOSITORY_PATH = RAILS_ROOT.gsub(%r{config\/\.\.}, '') + '/tmp/test/bazaar_repository'
  REPOSITORY_PATH.gsub!(/\/+/, '/')

  def setup
    @project = Project.find(3)
    @repository = Repository::Bazaar.create(
              :project => @project, :url => "file:///#{REPOSITORY_PATH}",
              :log_encoding => 'UTF-8')
    assert @repository
  end

  if File.directory?(REPOSITORY_PATH)
    def test_fetch_changesets_from_scratch
      @repository.fetch_changesets
      @repository.reload

      assert_equal 4, @repository.changesets.count
      assert_equal 9, @repository.changes.count
      assert_equal 'Initial import', @repository.changesets.find_by_revision('1').comments
    end

    def test_fetch_changesets_incremental
      @repository.fetch_changesets
      # Remove changesets with revision > 5
      @repository.changesets.find(:all).each {|c| c.destroy if c.revision.to_i > 2}
      @repository.reload
      assert_equal 2, @repository.changesets.count

      @repository.fetch_changesets
      assert_equal 4, @repository.changesets.count
    end

    def test_entries
      entries = @repository.entries
      assert_equal 2, entries.size

      assert_equal 'dir', entries[0].kind
      assert_equal 'directory', entries[0].name

      assert_equal 'file', entries[1].kind
      assert_equal 'doc-mkdir.txt', entries[1].name
    end

    def test_entries_in_subdirectory
      entries = @repository.entries('directory')
      assert_equal 3, entries.size

      assert_equal 'file', entries.last.kind
      assert_equal 'edit.png', entries.last.name
    end

    def test_previous
      @repository.fetch_changesets
      @repository.reload
      changeset = @repository.find_changeset_by_name('3')
      assert_equal @repository.find_changeset_by_name('2'), changeset.previous
    end

    def test_previous_nil
      @repository.fetch_changesets
      @repository.reload
      changeset = @repository.find_changeset_by_name('1')
      assert_nil changeset.previous
    end

    def test_next
      @repository.fetch_changesets
      @repository.reload
      changeset = @repository.find_changeset_by_name('2')
      assert_equal @repository.find_changeset_by_name('3'), changeset.next
    end

    def test_next_nil
      @repository.fetch_changesets
      @repository.reload
      changeset = @repository.find_changeset_by_name('4')
      assert_nil changeset.next
    end
  else
    should "Bazaar test repository not found."
    def test_fake; assert true end
  end
end
