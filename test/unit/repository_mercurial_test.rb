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
  
  def setup
    @project = Project.find(1)
    assert @repository = Repository::Mercurial.create(:project => @project, :url => REPOSITORY_PATH)
  end
  
  if File.directory?(REPOSITORY_PATH)  
    def test_fetch_changesets_from_scratch
      @repository.fetch_changesets
      @repository.reload
      
      assert_equal 17, @repository.changesets.count
      assert_equal 25, @repository.changes.count
      assert_equal "Initial import.\nThe repository contains 3 files.", @repository.changesets.find_by_revision('0').comments
    end
    
    def test_fetch_changesets_incremental
      @repository.fetch_changesets
      # Remove changesets with revision > 2
      @repository.changesets.find(:all).each {|c| c.destroy if c.revision.to_i > 2}
      @repository.reload
      assert_equal 3, @repository.changesets.count
      
      @repository.fetch_changesets
      assert_equal 17, @repository.changesets.count
    end
    
    def test_entries
      assert_equal 2, @repository.entries("sources", 2).size
      assert_equal 1, @repository.entries("sources", 3).size
    end

    def test_locate_on_outdated_repository
      assert_equal 1, @repository.entries("images", 0).size
      assert_equal 2, @repository.entries("images").size
      assert_equal 2, @repository.entries("images", 2).size
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
      assert_equal @repository.latest_changesets('', nil)[0, 2], changesets

      # with_filepath
      changesets = @repository.latest_changesets('/sql_escape/percent%dir/percent%file1.txt', nil)
      assert_equal %w|11 10 9|, changesets.collect(&:revision)

      changesets = @repository.latest_changesets('/sql_escape/underscore_dir/understrike_file.txt', nil)
      assert_equal %w|12 9|, changesets.collect(&:revision)
    end
  else
    puts "Mercurial test repository NOT FOUND. Skipping unit tests !!!"
    def test_fake; assert true end
  end
end
