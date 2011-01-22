require File.expand_path('../../../../../../test_helper', __FILE__)
begin
  require 'mocha'
  
  class DarcsAdapterTest < ActiveSupport::TestCase
    
    REPOSITORY_PATH = RAILS_ROOT.gsub(%r{config\/\.\.}, '') + '/tmp/test/darcs_repository'

    if File.directory?(REPOSITORY_PATH)
      def setup
        @adapter = Redmine::Scm::Adapters::DarcsAdapter.new(REPOSITORY_PATH)
      end

    else
      puts "Darcs test repository NOT FOUND. Skipping unit tests !!!"
      def test_fake; assert true end
    end
  end

rescue LoadError
  class DarcsMochaFake < ActiveSupport::TestCase
    def test_fake; assert(false, "Requires mocha to run those tests")  end
  end
end

