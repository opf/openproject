require File.dirname(__FILE__) + '/../test_helper'

class GitAdapterTest < Test::Unit::TestCase
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
  else
    puts "Git test repository NOT FOUND. Skipping unit tests !!!"
    def test_fake; assert true end
  end
end
