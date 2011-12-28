#-- encoding: UTF-8
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

      def test_cat
        cat = @adapter.cat('directory/document.txt')
        assert cat =~ /Write the contents of a file as of a given revision to standard output/
      end

      def test_annotate
        annotate = @adapter.annotate('doc-mkdir.txt')
        assert_equal 17, annotate.lines.size
        assert_equal '1', annotate.revisions[0].identifier
        assert_equal 'jsmith@', annotate.revisions[0].author
        assert_equal 'mkdir', annotate.lines[0]
      end

      private

      def test_scm_version_for(scm_command_version, version)
        @adapter.class.expects(:scm_version_from_command_line).returns(scm_command_version)
        assert_equal version, @adapter.class.scm_command_version
      end
    else
      should "Bazaar test repository NOT FOUND."
      def test_fake; assert true end
    end
  end

rescue LoadError
  class BazaarMochaFake < ActiveSupport::TestCase
    def test_fake; assert(false, "Requires mocha to run those tests")  end
  end
end

