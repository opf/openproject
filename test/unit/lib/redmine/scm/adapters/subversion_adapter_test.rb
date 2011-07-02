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

begin
  require 'mocha'

  class SubversionAdapterTest < ActiveSupport::TestCase

    if repository_configured?('subversion')
      def setup
        @adapter = Redmine::Scm::Adapters::SubversionAdapter.new(self.class.subversion_repository_url)
      end

      def test_client_version
        v = Redmine::Scm::Adapters::SubversionAdapter.client_version
        assert v.is_a?(Array)
      end

      def test_scm_version
        to_test = { "svn, version 1.6.13 (r1002816)\n"  => [1,6,13],
                    "svn, versione 1.6.13 (r1002816)\n" => [1,6,13],
                    "1.6.1\n1.7\n1.8"                   => [1,6,1],
                    "1.6.2\r\n1.8.1\r\n1.9.1"           => [1,6,2]}
        to_test.each do |s, v|
          test_scm_version_for(s, v)
        end
      end

      private

      def test_scm_version_for(scm_version, version)
        @adapter.class.expects(:scm_version_from_command_line).returns(scm_version)
        assert_equal version, @adapter.class.svn_binary_version
      end

    else
      puts "Subversion test repository NOT FOUND. Skipping unit tests !!!"
      def test_fake; assert true end
    end
  end

rescue LoadError
  class SubversionMochaFake < ActiveSupport::TestCase
    def test_fake; assert(false, "Requires mocha to run those tests")  end
  end
end
