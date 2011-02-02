require File.expand_path('../../../../../../test_helper', __FILE__)
begin
  require 'mocha'
  
  class CvsAdapterTest < ActiveSupport::TestCase
    
    REPOSITORY_PATH = RAILS_ROOT.gsub(%r{config\/\.\.}, '') + '/tmp/test/cvs_repository'
    MODULE_NAME = 'test'

    if File.directory?(REPOSITORY_PATH)  
      def setup
        @adapter = Redmine::Scm::Adapters::CvsAdapter.new(MODULE_NAME, REPOSITORY_PATH)
      end

      def test_revisions_all
        cnt = 0
        @adapter.revisions('', nil, nil, :with_paths => true) do |revision|
          cnt += 1
        end
        assert_equal 14, cnt
      end
    else
      puts "Cvs test repository NOT FOUND. Skipping unit tests !!!"
      def test_fake; assert true end
    end
  end

rescue LoadError
  class CvsMochaFake < ActiveSupport::TestCase
    def test_fake; assert(false, "Requires mocha to run those tests")  end
  end
end

