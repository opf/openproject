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

  class CvsAdapterTest < ActiveSupport::TestCase

    REPOSITORY_PATH = RAILS_ROOT.gsub(%r{config\/\.\.}, '') + '/tmp/test/cvs_repository'
    REPOSITORY_PATH.gsub!(/\//, "\\") if Redmine::Platform.mswin?
    MODULE_NAME = 'test'

    if File.directory?(REPOSITORY_PATH)
      def setup
        @adapter = Redmine::Scm::Adapters::CvsAdapter.new(MODULE_NAME, REPOSITORY_PATH)
      end

      def test_scm_version
        to_test = { "\nConcurrent Versions System (CVS) 1.12.13 (client/server)\n"  => [1,12,13],
                    "\r\n1.12.12\r\n1.12.11"                   => [1,12,12],
                    "1.12.11\r\n1.12.10\r\n"                   => [1,12,11]}
        to_test.each do |s, v|
          test_scm_version_for(s, v)
        end
      end

      def test_revisions_all
        cnt = 0
        @adapter.revisions('', nil, nil, :with_paths => true) do |revision|
          cnt += 1
        end
        assert_equal 14, cnt
      end

      def test_revisions_from_rev3
        rev3_committed_on = Time.gm(2007, 12, 13, 16, 27, 22)
        cnt = 0
        @adapter.revisions('', rev3_committed_on, nil, :with_paths => true) do |revision|
          cnt += 1
        end
        assert_equal 2, cnt
      end

      def test_entries_rev3
        rev3_committed_on = Time.gm(2007, 12, 13, 16, 27, 22)
        entries = @adapter.entries('sources', rev3_committed_on)
        assert_equal 2, entries.size
        assert_equal entries[0].name, "watchers_controller.rb"
        assert_equal entries[0].lastrev.time, Time.gm(2007, 12, 13, 16, 27, 22)
      end

      private

      def test_scm_version_for(scm_command_version, version)
        @adapter.class.expects(:scm_version_from_command_line).returns(scm_command_version)
        assert_equal version, @adapter.class.scm_command_version
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

