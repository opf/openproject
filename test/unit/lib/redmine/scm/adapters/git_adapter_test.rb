require File.expand_path('../../../../../../test_helper', __FILE__)

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
      assert_equal 15, @adapter.revisions('',nil,nil,:all => true).length
    end
    
    def test_getting_certain_revisions
      assert_equal 1, @adapter.revisions('','899a15d^','899a15d').length
    end
    
    def test_getting_revisions_with_spaces_in_filename
      assert_equal 1, @adapter.revisions("filemane with spaces.txt", nil, nil, :all => true).length
    end
    
    def test_getting_revisions_with_leading_and_trailing_spaces_in_filename
      assert_equal " filename with a leading space.txt ", @adapter.revisions(" filename with a leading space.txt ", nil, nil, :all => true)[0].paths[0][:path]
    end
    
    def test_getting_entries_with_leading_and_trailing_spaces_in_filename
      assert_equal " filename with a leading space.txt ", @adapter.entries('', '83ca5fd546063a3c7dc2e568ba3355661a9e2b2c')[3].name
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
    
    def test_last_rev
      last_rev = @adapter.lastrev("README", "4f26664364207fa8b1af9f8722647ab2d4ac5d43")
      assert_equal "4a07fe31bffcf2888791f3e6cbc9c4545cefe3e8", last_rev.scmid
      assert_equal "4a07fe31bffcf2888791f3e6cbc9c4545cefe3e8", last_rev.identifier
      assert_equal "Adam Soltys <asoltys@gmail.com>", last_rev.author
      assert_equal "2009-06-24 05:27:38".to_time, last_rev.time
    end
    
    def test_last_rev_with_spaces_in_filename
      last_rev = @adapter.lastrev("filemane with spaces.txt", "ed5bb786bbda2dee66a2d50faf51429dbc043a7b")
      assert_equal "ed5bb786bbda2dee66a2d50faf51429dbc043a7b", last_rev.scmid
      assert_equal "ed5bb786bbda2dee66a2d50faf51429dbc043a7b", last_rev.identifier
      assert_equal "Felix Schäfer <felix@fachschaften.org>", last_rev.author
      assert_equal "2010-09-18 19:59:46".to_time, last_rev.time
    end
  else
    puts "Git test repository NOT FOUND. Skipping unit tests !!!"
    def test_fake; assert true end
  end
end
