require File.dirname(__FILE__) + '/../../../../../test_helper'

class GitAdapterTest < ActiveSupport::TestCase
  REPOSITORY_PATH = RAILS_ROOT.gsub(%r{config\/\.\.}, '') + '/tmp/test/git_repository'

  if File.directory?(REPOSITORY_PATH)  
    def setup
      @adapter = Redmine::Scm::Adapters::GitAdapter.new(REPOSITORY_PATH)
    end

    def test_branches
      assert_equal @adapter.branches, ['master', 'test_branch']
    end

    def test_getting_all_revisions
      assert_equal 13, @adapter.revisions('',nil,nil,:all => true).length
    end
    
    def test_getting_certain_revisions
      assert_equal 1, @adapter.revisions('','899a15d^','899a15d').length
    end
    
    def test_annotate
      annotate = @adapter.annotate('sources/watchers_controller.rb')
      assert_kind_of Redmine::Scm::Adapters::Annotate, annotate
      assert_equal 41, annotate.lines.size
      assert_equal "# This program is free software; you can redistribute it and/or", annotate.lines[4].strip
      assert_equal "7234cb2750b63f47bff735edc50a1c0a433c2518", annotate.revisions[4].identifier
      assert_equal "jsmith", annotate.revisions[4].author
    end
    
    def test_annotate_moved_file
      annotate = @adapter.annotate('renamed_test.txt')
      assert_kind_of Redmine::Scm::Adapters::Annotate, annotate
      assert_equal 2, annotate.lines.size
    end
  else
    puts "Git test repository NOT FOUND. Skipping unit tests !!!"
    def test_fake; assert true end
  end
end
