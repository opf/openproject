require File.dirname(__FILE__) + '/../test_helper'

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
      assert_equal 12, @adapter.revisions('',nil,nil,:all => true).length
    end
    
    def test_annotate
      annotate = @adapter.annotate('sources/watchers_controller.rb')
      assert_kind_of Redmine::Scm::Adapters::Annotate, annotate
      assert_equal 41, annotate.lines.size
    end
    
    def test_annotate_moved_file
      annotate = @adapter.annotate('renamed_test.txt')
      assert_kind_of Redmine::Scm::Adapters::Annotate, annotate
      assert_equal 2, annotate.lines.size
      assert_equal "Let's pretend I'm adding a new feature!", annotate.lines.second
      assert_equal "7e61ac704deecde634b51e59daa8110435dcb3da", annotate.revisions.second.identifier
    end
  else
    puts "Git test repository NOT FOUND. Skipping unit tests !!!"
    def test_fake; assert true end
  end
end
