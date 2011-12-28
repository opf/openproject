#-- encoding: UTF-8
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


require File.expand_path('../../../../../../test_helper', __FILE__)

class FilesystemAdapterTest < ActiveSupport::TestCase

  REPOSITORY_PATH = RAILS_ROOT.gsub(%r{config\/\.\.}, '') + '/tmp/test/filesystem_repository'

  if File.directory?(REPOSITORY_PATH)
    def setup
      @adapter = Redmine::Scm::Adapters::FilesystemAdapter.new(REPOSITORY_PATH)
    end

    def test_entries
      assert_equal 3, @adapter.entries.size
      assert_equal ["dir", "japanese", "test"], @adapter.entries.collect(&:name)
      assert_equal ["dir", "japanese", "test"], @adapter.entries(nil).collect(&:name)
      assert_equal ["dir", "japanese", "test"], @adapter.entries("/").collect(&:name)
      ["dir", "/dir", "/dir/", "dir/"].each do |path|
        assert_equal ["subdir", "dirfile"], @adapter.entries(path).collect(&:name)
      end
      # If y try to use "..", the path is ignored
      ["/../","dir/../", "..", "../", "/..", "dir/.."].each do |path|
        assert_equal ["dir", "japanese", "test"], @adapter.entries(path).collect(&:name),
             ".. must be ignored in path argument"
      end
    end

    def test_cat
      assert_equal "TEST CAT\n", @adapter.cat("test")
      assert_equal "TEST CAT\n", @adapter.cat("/test")
      # Revision number is ignored
      assert_equal "TEST CAT\n", @adapter.cat("/test", 1)
    end
  else
    should "Filesystem test repository not found."
    def test_fake; assert true end
  end
end
