require File.expand_path('../../../../../../test_helper', __FILE__)
begin
  require 'mocha'

  class BazaarAdapterTest < ActiveSupport::TestCase

    REPOSITORY_PATH = RAILS_ROOT.gsub(%r{config\/\.\.}, '') + '/tmp/test/bazaar_repository'
    REPOSITORY_PATH.gsub!(/\/+/, '/')

    if File.directory?(REPOSITORY_PATH)  
      def setup
        @adapter = Redmine::Scm::Adapters::BazaarAdapter.new(REPOSITORY_PATH)
      end

      def test_scm_version
        to_test = { "Bazaar (bzr) 2.1.2\n"             => [2,1,2],
                    "2.1.1\n1.7\n1.8"                  => [2,1,1],
                    "2.0.1\r\n1.8.1\r\n1.9.1"          => [2,0,1]}
        to_test.each do |s, v|
          test_scm_version_for(s, v)
        end
      end

      private

      def test_scm_version_for(scm_command_version, version)
        @adapter.class.expects(:scm_version_from_command_line).returns(scm_command_version)
        assert_equal version, @adapter.class.scm_command_version
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

