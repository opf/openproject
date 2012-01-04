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

class RepositoryFilesystemTest < ActiveSupport::TestCase
  fixtures :projects

  # No '..' in the repository path
  REPOSITORY_PATH = RAILS_ROOT.gsub(%r{config\/\.\.}, '') + '/tmp/test/filesystem_repository'

  def setup
    @project = Project.find(3)
    Setting.enabled_scm = Setting.enabled_scm.dup << 'Filesystem' unless Setting.enabled_scm.include?('Filesystem')
    assert @repository = Repository::Filesystem.create(
                            :project => @project, :url => REPOSITORY_PATH)
  end

  if File.directory?(REPOSITORY_PATH)
    def test_fetch_changesets
      @repository.fetch_changesets
      @repository.reload

      assert_equal 0, @repository.changesets.count
      assert_equal 0, @repository.changes.count
    end

    def test_entries
      assert_equal 3, @repository.entries("", 2).size
      assert_equal 2, @repository.entries("dir", 3).size
    end

    def test_cat
      assert_equal "TEST CAT\n", @repository.scm.cat("test")
    end

  else
    should "Filesystem test repository not found."
    def test_fake; assert true end
  end
end
