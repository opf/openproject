# redMine - project management software
# Copyright (C) 2006-2007  Jean-Philippe Lang
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

require File.expand_path('../../test_helper', __FILE__)

class RepositoryMercurialTest < ActiveSupport::TestCase
  fixtures :projects
  
  # No '..' in the repository path
  REPOSITORY_PATH = RAILS_ROOT.gsub(%r{config\/\.\.}, '') + '/tmp/test/mercurial_repository'

  CHAR_1_HEX = "\xc3\x9c"

  def setup
    @project = Project.find(3)
    @repository = Repository::Mercurial.create(
                      :project => @project,
                      :url     => REPOSITORY_PATH,
                      :path_encoding => 'ISO-8859-1'
                      )
    assert @repository
    @char_1        = CHAR_1_HEX.dup
    @tag_char_1    = "tag-#{CHAR_1_HEX}-00"
    @branch_char_0 = "branch-#{CHAR_1_HEX}-00"
    @branch_char_1 = "branch-#{CHAR_1_HEX}-01"
    if @char_1.respond_to?(:force_encoding)
      @char_1.force_encoding('UTF-8')
      @tag_char_1.force_encoding('UTF-8')
      @branch_char_0.force_encoding('UTF-8')
      @branch_char_1.force_encoding('UTF-8')
    end
  end

  if File.directory?(REPOSITORY_PATH)  
    def test_fetch_changesets_from_scratch
      @repository.fetch_changesets
      @repository.reload
      assert_equal 29, @repository.changesets.count
      assert_equal 37, @repository.changes.count
      assert_equal "Initial import.\nThe repository contains 3 files.",
                   @repository.changesets.find_by_revision('0').comments
    end

    def test_fetch_changesets_incremental
      @repository.fetch_changesets
      # Remove changesets with revision > 2
      @repository.changesets.find(:all).each {|c| c.destroy if c.revision.to_i > 2}
      @repository.reload
      assert_equal 3, @repository.changesets.count
      
      @repository.fetch_changesets
      assert_equal 29, @repository.changesets.count
    end

    def test_isodatesec
      # Template keyword 'isodatesec' supported in Mercurial 1.0 and higher
      if @repository.scm.class.client_version_above?([1, 0])
        @repository.fetch_changesets
        @repository.reload
        rev0_committed_on = Time.gm(2007, 12, 14, 9, 22, 52)
        assert_equal @repository.changesets.find_by_revision('0').committed_on, rev0_committed_on
      end
    end

    def test_changeset_order_by_revision
      @repository.fetch_changesets
      @repository.reload

      c0 = @repository.latest_changeset
      c1 = @repository.changesets.find_by_revision('0')
      # sorted by revision (id), not by date
      assert c0.revision.to_i > c1.revision.to_i
      assert c0.committed_on  < c1.committed_on
    end

    def test_latest_changesets
      @repository.fetch_changesets
      @repository.reload

      # with_limit
      changesets = @repository.latest_changesets('', nil, 2)
      assert_equal %w|28 27|, changesets.collect(&:revision)

      # with_filepath
      changesets = @repository.latest_changesets(
                      '/sql_escape/percent%dir/percent%file1.txt', nil)
      assert_equal %w|11 10 9|, changesets.collect(&:revision)

      changesets = @repository.latest_changesets(
                      '/sql_escape/underscore_dir/understrike_file.txt', nil)
      assert_equal %w|12 9|, changesets.collect(&:revision)

      changesets = @repository.latest_changesets('README', nil)
      assert_equal %w|28 17 8 6 1 0|, changesets.collect(&:revision)

      changesets = @repository.latest_changesets('README','8')
      assert_equal %w|8 6 1 0|, changesets.collect(&:revision)

      changesets = @repository.latest_changesets('README','8', 2)
      assert_equal %w|8 6|, changesets.collect(&:revision)

      # with_dirpath
      changesets = @repository.latest_changesets('images', nil)
      assert_equal %w|1 0|, changesets.collect(&:revision)

      path = 'sql_escape/percent%dir'
      changesets = @repository.latest_changesets(path, nil)
      assert_equal %w|13 11 10 9|, changesets.collect(&:revision)

      changesets = @repository.latest_changesets(path, '11')
      assert_equal %w|11 10 9|, changesets.collect(&:revision)

      changesets = @repository.latest_changesets(path, '11', 2)
      assert_equal %w|11 10|, changesets.collect(&:revision)

      path = 'sql_escape/underscore_dir'
      changesets = @repository.latest_changesets(path, nil)
      assert_equal %w|13 12 9|, changesets.collect(&:revision)

      changesets = @repository.latest_changesets(path, '12')
      assert_equal %w|12 9|, changesets.collect(&:revision)

      changesets = @repository.latest_changesets(path, '12', 1)
      assert_equal %w|12|, changesets.collect(&:revision)
    end

    def test_copied_files
      @repository.fetch_changesets
      @repository.reload

      cs1 = @repository.changesets.find_by_revision('13')
      assert_not_nil cs1
      c1  = cs1.changes.sort_by(&:path)
      assert_equal 2, c1.size

      assert_equal 'A', c1[0].action
      assert_equal '/sql_escape/percent%dir/percentfile1.txt',  c1[0].path
      assert_equal '/sql_escape/percent%dir/percent%file1.txt', c1[0].from_path

      assert_equal 'A', c1[1].action
      assert_equal '/sql_escape/underscore_dir/understrike-file.txt', c1[1].path
      assert_equal '/sql_escape/underscore_dir/understrike_file.txt', c1[1].from_path

      cs2 = @repository.changesets.find_by_revision('15')
      c2  = cs2.changes
      assert_equal 1, c2.size

      assert_equal 'A', c2[0].action
      assert_equal '/README (1)[2]&,%.-3_4', c2[0].path
      assert_equal '/README', c2[0].from_path

      cs3 = @repository.changesets.find_by_revision('19')
      c3  = cs3.changes
      assert_equal 1, c3.size
      assert_equal 'A', c3[0].action
      assert_equal "/latin-1-dir/test-#{@char_1}-1.txt",  c3[0].path
      assert_equal "/latin-1-dir/test-#{@char_1}.txt",    c3[0].from_path
    end

    def test_find_changeset_by_name
      @repository.fetch_changesets
      @repository.reload
      %w|2 400bb8672109 400|.each do |r|
        assert_equal '2', @repository.find_changeset_by_name(r).revision
      end
    end

    def test_find_changeset_by_invalid_name
      @repository.fetch_changesets
      @repository.reload
      assert_nil @repository.find_changeset_by_name('100000')
    end

    def test_identifier
      @repository.fetch_changesets
      @repository.reload
      c = @repository.changesets.find_by_revision('2')
      assert_equal c.scmid, c.identifier
    end

    def test_format_identifier
      @repository.fetch_changesets
      @repository.reload
      c = @repository.changesets.find_by_revision('2')
      assert_equal '2:400bb8672109', c.format_identifier
    end

    def test_find_changeset_by_empty_name
      @repository.fetch_changesets
      @repository.reload
      ['', ' ', nil].each do |r|
        assert_nil @repository.find_changeset_by_name(r)
      end
    end

    def test_activities
      c = Changeset.new(:repository   => @repository,
                        :committed_on => Time.now,
                        :revision     => '123',
                        :scmid        => 'abc400bb8672',
                        :comments     => 'test')
      assert c.event_title.include?('123:abc400bb8672:')
      assert_equal 'abc400bb8672', c.event_url[:rev]
    end

    def test_previous
      @repository.fetch_changesets
      @repository.reload
      %w|28 3ae45e2d177d 3ae45|.each do |r1|
        changeset = @repository.find_changeset_by_name(r1)
        %w|27 7bbf4c738e71 7bbf|.each do |r2|
          assert_equal @repository.find_changeset_by_name(r2), changeset.previous
        end
      end
    end

    def test_previous_nil
      @repository.fetch_changesets
      @repository.reload
      %w|0 0885933ad4f6 0885|.each do |r1|
        changeset = @repository.find_changeset_by_name(r1)
        assert_nil changeset.previous
      end
    end

    def test_next
      @repository.fetch_changesets
      @repository.reload
      %w|27 7bbf4c738e71 7bbf|.each do |r2|
        changeset = @repository.find_changeset_by_name(r2)
        %w|28 3ae45e2d177d 3ae45|.each do |r1|
        assert_equal @repository.find_changeset_by_name(r1), changeset.next
        end
      end
    end

    def test_next_nil
      @repository.fetch_changesets
      @repository.reload
      %w|28 3ae45e2d177d 3ae45|.each do |r1|
        changeset = @repository.find_changeset_by_name(r1)
        assert_nil changeset.next
      end
    end
  else
    puts "Mercurial test repository NOT FOUND. Skipping unit tests !!!"
    def test_fake; assert true end
  end
end
