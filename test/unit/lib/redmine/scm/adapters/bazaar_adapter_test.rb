require File.expand_path('../../../../../../test_helper', __FILE__)
begin
  require 'mocha'

  class BazaarAdapterTest < ActiveSupport::TestCase

    REPOSITORY_PATH = RAILS_ROOT.gsub(%r{config\/\.\.}, '') + '/tmp/test/bazaar_repository'

    if File.directory?(REPOSITORY_PATH)  
      def setup
        @adapter = Redmine::Scm::Adapters::BazaarAdapter.new(MODULE_NAME, REPOSITORY_PATH)
      end

    else
      puts "Bazaar test repository NOT FOUND. Skipping unit tests !!!"
      def test_fake; assert true end
    end
  end

rescue LoadError
  class BazaarMochaFake < ActiveSupport::TestCase
    def test_fake; assert(false, "Requires mocha to run those tests")  end
  end
end

