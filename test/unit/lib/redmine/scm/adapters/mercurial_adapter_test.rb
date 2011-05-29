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

  class MercurialAdapterTest < ActiveSupport::TestCase

    HELPERS_DIR = Redmine::Scm::Adapters::MercurialAdapter::HELPERS_DIR
    TEMPLATE_NAME = Redmine::Scm::Adapters::MercurialAdapter::TEMPLATE_NAME
    TEMPLATE_EXTENSION = Redmine::Scm::Adapters::MercurialAdapter::TEMPLATE_EXTENSION

    REPOSITORY_PATH = RAILS_ROOT.gsub(%r{config\/\.\.}, '') + '/tmp/test/mercurial_repository'

    CHAR_1_HEX = "\xc3\x9c"

    if File.directory?(REPOSITORY_PATH)
      def setup
        @adapter = Redmine::Scm::Adapters::MercurialAdapter.new(
                              REPOSITORY_PATH,
                              nil,
                              nil,
                              nil,
                             'ISO-8859-1')
        @diff_c_support = true

        @char_1        = CHAR_1_HEX.dup
        @tag_char_1    = "tag-#{CHAR_1_HEX}-00"
        @branch_char_0 = "branch-#{CHAR_1_HEX}-00"
        @branch_char_1 = "branch-#{CHAR_1_HEX}-01"
        if @tag_char_1.respond_to?(:force_encoding)
          @char_1.force_encoding('UTF-8')
          @tag_char_1.force_encoding('UTF-8')
          @branch_char_0.force_encoding('UTF-8')
          @branch_char_1.force_encoding('UTF-8')
        end
      end

      def test_hgversion
        to_test = { "Mercurial Distributed SCM (version 0.9.5)\n"  => [0,9,5],
                    "Mercurial Distributed SCM (1.0)\n"            => [1,0],
                    "Mercurial Distributed SCM (1e4ddc9ac9f7+20080325)\n" => nil,
                    "Mercurial Distributed SCM (1.0.1+20080525)\n" => [1,0,1],
                    "Mercurial Distributed SCM (1916e629a29d)\n"   => nil,
                    "Mercurial SCM Distribuito (versione 0.9.5)\n" => [0,9,5],
                    "(1.6)\n(1.7)\n(1.8)"                          => [1,6],
                    "(1.7.1)\r\n(1.8.1)\r\n(1.9.1)"                => [1,7,1]}

        to_test.each do |s, v|
          test_hgversion_for(s, v)
        end
      end

      def test_template_path
        to_test = { [0,9,5]  => "0.9.5",
                    [1,0]    => "1.0",
                    []       => "1.0",
                    [1,0,1]  => "1.0",
                    [1,7]    => "1.0",
                    [1,7,1]  => "1.0" }
        to_test.each do |v, template|
          test_template_path_for(v, template)
        end
      end

      def test_info
        [REPOSITORY_PATH, REPOSITORY_PATH + "/",
             REPOSITORY_PATH + "//"].each do |repo|
          adp = Redmine::Scm::Adapters::MercurialAdapter.new(repo)
          repo_path =  adp.info.root_url.gsub(/\\/, "/")
          assert_equal REPOSITORY_PATH, repo_path
          assert_equal '28', adp.info.lastrev.revision
          assert_equal '3ae45e2d177d',adp.info.lastrev.scmid
        end
      end

      def test_revisions
        revisions = @adapter.revisions(nil, 2, 4)
        assert_equal 3, revisions.size
        assert_equal '2', revisions[0].revision
        assert_equal '400bb8672109', revisions[0].scmid
        assert_equal '4', revisions[2].revision
        assert_equal 'def6d2f1254a', revisions[2].scmid

        revisions = @adapter.revisions(nil, 2, 4, {:limit => 2})
        assert_equal 2, revisions.size
        assert_equal '2', revisions[0].revision
        assert_equal '400bb8672109', revisions[0].scmid
      end

      def test_diff
        if @adapter.class.client_version_above?([1, 2])
          assert_nil @adapter.diff(nil, '100000')
        end
        assert_nil @adapter.diff(nil, '100000', '200000')
        [2, '400bb8672109', '400', 400].each do |r1|
          diff1 = @adapter.diff(nil, r1)
          if @diff_c_support
            assert_equal 28, diff1.size
            buf = diff1[24].gsub(/\r\n|\r|\n/, "")
            assert_equal "+    return true unless klass.respond_to?('watched_by')", buf
          else
            assert_equal 0, diff1.size
          end
          [4, 'def6d2f1254a'].each do |r2|
            diff2 = @adapter.diff(nil,r1,r2)
            assert_equal 49, diff2.size
            buf =  diff2[41].gsub(/\r\n|\r|\n/, "")
            assert_equal "+class WelcomeController < ApplicationController", buf
            diff3 = @adapter.diff('sources/watchers_controller.rb', r1, r2)
            assert_equal 20, diff3.size
            buf =  diff3[12].gsub(/\r\n|\r|\n/, "")
            assert_equal "+    @watched.remove_watcher(user)", buf
          end
        end
      end

      def test_diff_made_by_revision
        if @diff_c_support
          [24, '24', '4cddb4e45f52'].each do |r1|
            diff1 = @adapter.diff(nil, r1)
            assert_equal 5, diff1.size
            buf = diff1[4].gsub(/\r\n|\r|\n/, "")
            assert_equal '+0885933ad4f68d77c2649cd11f8311276e7ef7ce tag-init-revision', buf
          end
        end
      end

      def test_cat
        [2, '400bb8672109', '400', 400].each do |r|
          buf = @adapter.cat('sources/welcome_controller.rb', r)
          assert buf
          lines = buf.split("\r\n")
          assert_equal 25, lines.length
          assert_equal 'class WelcomeController < ApplicationController', lines[17]
        end
        assert_nil @adapter.cat('sources/welcome_controller.rb')
      end

      def test_annotate
        assert_equal [], @adapter.annotate("sources/welcome_controller.rb").lines
        [2, '400bb8672109', '400', 400].each do |r|
          ann = @adapter.annotate('sources/welcome_controller.rb', r)
          assert ann
          assert_equal '1', ann.revisions[17].revision
          assert_equal '9d5b5b004199', ann.revisions[17].identifier
          assert_equal 'jsmith', ann.revisions[0].author
          assert_equal 25, ann.lines.length
          assert_equal 'class WelcomeController < ApplicationController', ann.lines[17]
        end
      end

      def test_entries
        assert_nil @adapter.entries(nil, '100000')

        assert_equal 1, @adapter.entries("sources", 3).size
        assert_equal 1, @adapter.entries("sources", 'b3a615152df8').size

        [2, '400bb8672109', '400', 400].each do |r|
          entries1 = @adapter.entries(nil, r)
          assert entries1
          assert_equal 3, entries1.size
          assert_equal 'sources', entries1[1].name
          assert_equal 'sources', entries1[1].path
          assert_equal 'dir', entries1[1].kind
          readme = entries1[2]
          assert_equal 'README', readme.name
          assert_equal 'README', readme.path
          assert_equal 'file', readme.kind
          assert_equal 27, readme.size
          assert_equal '1', readme.lastrev.revision
          assert_equal '9d5b5b004199', readme.lastrev.identifier
          # 2007-12-14 10:24:01 +0100
          assert_equal Time.gm(2007, 12, 14, 9, 24, 1), readme.lastrev.time

          entries2 = @adapter.entries('sources', r)
          assert entries2
          assert_equal 2, entries2.size
          assert_equal 'watchers_controller.rb', entries2[0].name
          assert_equal 'sources/watchers_controller.rb', entries2[0].path
          assert_equal 'file', entries2[0].kind
          assert_equal 'welcome_controller.rb', entries2[1].name
          assert_equal 'sources/welcome_controller.rb', entries2[1].path
          assert_equal 'file', entries2[1].kind
        end
      end

      def test_entries_tag
        entries1 = @adapter.entries(nil, 'tag_test.00')
        assert entries1
        assert_equal 3, entries1.size
        assert_equal 'sources', entries1[1].name
        assert_equal 'sources', entries1[1].path
        assert_equal 'dir', entries1[1].kind
        readme = entries1[2]
        assert_equal 'README', readme.name
        assert_equal 'README', readme.path
        assert_equal 'file', readme.kind
        assert_equal 21, readme.size
        assert_equal '0', readme.lastrev.revision
        assert_equal '0885933ad4f6', readme.lastrev.identifier
        # 2007-12-14 10:22:52 +0100
        assert_equal Time.gm(2007, 12, 14, 9, 22, 52), readme.lastrev.time
      end

      def test_entries_branch
        entries1 = @adapter.entries(nil, 'test-branch-00')
        assert entries1
        assert_equal 5, entries1.size
        assert_equal 'sql_escape', entries1[2].name
        assert_equal 'sql_escape', entries1[2].path
        assert_equal 'dir', entries1[2].kind
        readme = entries1[4]
        assert_equal 'README', readme.name
        assert_equal 'README', readme.path
        assert_equal 'file', readme.kind
        assert_equal 365, readme.size
        assert_equal '8', readme.lastrev.revision
        assert_equal 'c51f5bb613cd', readme.lastrev.identifier
        # 2001-02-01 00:00:00 -0900
        assert_equal Time.gm(2001, 2, 1, 9, 0, 0), readme.lastrev.time
      end

      def test_locate_on_outdated_repository
        assert_equal 1, @adapter.entries("images", 0).size
        assert_equal 2, @adapter.entries("images").size
        assert_equal 2, @adapter.entries("images", 2).size
      end

      def test_access_by_nodeid
        path = 'sources/welcome_controller.rb'
        assert_equal @adapter.cat(path, 2), @adapter.cat(path, '400bb8672109')
      end

      def test_access_by_fuzzy_nodeid
        path = 'sources/welcome_controller.rb'
        # falls back to nodeid
        assert_equal @adapter.cat(path, 2), @adapter.cat(path, '400')
      end

      def test_tags
        assert_equal [@tag_char_1, 'tag_test.00', 'tag-init-revision'], @adapter.tags
      end

      def test_tagmap
        tm = { 
          @tag_char_1         => 'adf805632193',
          'tag_test.00'       => '6987191f453a',
          'tag-init-revision' => '0885933ad4f6',
          }
        assert_equal tm, @adapter.tagmap
      end

      def test_branches
        assert_equal [
            'default',
            @branch_char_1,
            'branch (1)[2]&,%.-3_4',
            @branch_char_0,
            'test_branch.latin-1',
            'test-branch-00',
          ], @adapter.branches
      end

      def test_branchmap
        bm = {
           'default'               => '3ae45e2d177d',
           'test_branch.latin-1'   => 'c2ffe7da686a',
           'branch (1)[2]&,%.-3_4' => 'afc61e85bde7',
           'test-branch-00'        => '3a330eb32958',
           @branch_char_0          => 'c8d3e4887474',
           @branch_char_1          => '7bbf4c738e71',
         }
        assert_equal bm, @adapter.branchmap
      end

      def test_path_space
        p = 'README (1)[2]&,%.-3_4'
        [15, '933ca60293d7'].each do |r1|
          assert @adapter.diff(p, r1)
          assert @adapter.cat(p, r1)
          assert_equal 1, @adapter.annotate(p, r1).lines.length
          [25, 'afc61e85bde7'].each do |r2|
            assert @adapter.diff(p, r1, r2)
          end
        end
      end

      def test_tag_non_ascii
        p = "latin-1-dir/test-#{@char_1}-1.txt"
        assert @adapter.cat(p, @tag_char_1)
        assert_equal 1, @adapter.annotate(p, @tag_char_1).lines.length
      end

      def test_branch_non_ascii
        p = "latin-1-dir/test-#{@char_1}-subdir/test-#{@char_1}-1.txt"
        assert @adapter.cat(p, @branch_char_1)
        assert_equal 1, @adapter.annotate(p, @branch_char_1).lines.length
      end

      def test_nodes_in_branch
         [
            'default',
            @branch_char_1,
            'branch (1)[2]&,%.-3_4',
            @branch_char_0,
            'test_branch.latin-1',
            'test-branch-00',
               ].each do |bra|
          nib0 = @adapter.nodes_in_branch(bra)
          assert nib0
          nib1 = @adapter.nodes_in_branch(bra, :limit => 1)
          assert_equal 1, nib1.size
          case bra
            when 'branch (1)[2]&,%.-3_4'
              assert_equal 3, nib0.size
              assert_equal nib0[0], 'afc61e85bde7'
              nib2 = @adapter.nodes_in_branch(bra, :limit => 2)
              assert_equal 2, nib2.size
              assert_equal nib2[1], '933ca60293d7'
            when @branch_char_1
              assert_equal 2, nib0.size
              assert_equal nib0[1], '08ff3227303e'
              nib2 = @adapter.nodes_in_branch(bra, :limit => 1)
              assert_equal 1, nib2.size
              assert_equal nib2[0], '7bbf4c738e71'
          end
        end
      end

      private

      def test_hgversion_for(hgversion, version)
        @adapter.class.expects(:hgversion_from_command_line).returns(hgversion)
        assert_equal version, @adapter.class.hgversion
      end

      def test_template_path_for(version, template)
        assert_equal "#{HELPERS_DIR}/#{TEMPLATE_NAME}-#{template}.#{TEMPLATE_EXTENSION}",
                     @adapter.class.template_path_for(version)
        assert File.exist?(@adapter.class.template_path_for(version))
      end
    else
      puts "Mercurial test repository NOT FOUND. Skipping unit tests !!!"
      def test_fake; assert true end
    end
  end

rescue LoadError
  class MercurialMochaFake < ActiveSupport::TestCase
    def test_fake; assert(false, "Requires mocha to run those tests")  end
  end
end

