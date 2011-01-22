require File.expand_path('../../../../../../test_helper', __FILE__)
begin
  require 'mocha'
  
  class DarcsAdapterTest < ActiveSupport::TestCase
    
    REPOSITORY_PATH = RAILS_ROOT.gsub(%r{config\/\.\.}, '') + '/tmp/test/darcs_repository'

    if File.directory?(REPOSITORY_PATH)
      def setup
        @adapter = Redmine::Scm::Adapters::DarcsAdapter.new(REPOSITORY_PATH)
      end

      def test_darcsversion
        to_test = { "1.0.9 (release)\n"  => [1,0,9] ,
                    "2.2.0 (release)\n"  => [2,2,0] }
        to_test.each do |s, v|
          test_darcsversion_for(s, v)
        end
      end

      private

      def test_darcsversion_for(darcsversion, version)
        @adapter.class.expects(:darcs_binary_version_from_command_line).returns(darcsversion)
        assert_equal version, @adapter.class.darcs_binary_version
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

