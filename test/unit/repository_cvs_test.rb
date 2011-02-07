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
require 'pp'
class RepositoryCvsTest < ActiveSupport::TestCase
  fixtures :projects
  
  # No '..' in the repository path
  REPOSITORY_PATH = RAILS_ROOT.gsub(%r{config\/\.\.}, '') + '/tmp/test/cvs_repository'
  REPOSITORY_PATH.gsub!(/\//, "\\") if Redmine::Platform.mswin?
  # CVS module
  MODULE_NAME = 'test'
  
  def setup
    @project = Project.find(3)
    assert @repository = Repository::Cvs.create(:project => @project, 
                                                :root_url => REPOSITORY_PATH,
                                                :url => MODULE_NAME)
  end
  
  if File.directory?(REPOSITORY_PATH)  
    def test_fetch_changesets_from_scratch
      assert_equal 0, @repository.changesets.count
      @repository.fetch_changesets
      @repository.reload
      
      assert_equal 5, @repository.changesets.count
      assert_equal 14, @repository.changes.count
      assert_not_nil @repository.changesets.find_by_comments('Two files changed')
    end
    
    def test_fetch_changesets_incremental
      assert_equal 0, @repository.changesets.count
      @repository.fetch_changesets
      # Remove changesets with revision > 3
      @repository.changesets.find(:all).each {|c| c.destroy if c.revision.to_i > 3}
      @repository.reload
      assert_equal 3, @repository.changesets.count
      assert_equal %w|3 2 1|, @repository.changesets.collect(&:revision)

      rev3_commit = @repository.changesets.find(:first, :order => 'committed_on DESC')
      assert_equal '3', rev3_commit.revision
       # 2007-12-14 01:27:22 +0900
      rev3_committed_on = Time.gm(2007, 12, 13, 16, 27, 22)
      assert_equal rev3_committed_on, rev3_commit.committed_on
      latest_rev = @repository.latest_changeset
      assert_equal rev3_committed_on, latest_rev.committed_on

      @repository.fetch_changesets
      @repository.reload
      assert_equal 5, @repository.changesets.count

      assert_equal %w|5 4 3 2 1|, @repository.changesets.collect(&:revision)
      rev5_commit = @repository.changesets.find(:first, :order => 'committed_on DESC')
       # 2007-12-14 01:30:01 +0900
      rev5_committed_on = Time.gm(2007, 12, 13, 16, 30, 1)
      assert_equal rev5_committed_on, rev5_commit.committed_on
    end
    
    def test_deleted_files_should_not_be_listed
      assert_equal 0, @repository.changesets.count
      @repository.fetch_changesets
      @repository.reload
      assert_equal 5, @repository.changesets.count

      entries = @repository.entries('sources')
      assert entries.detect {|e| e.name == 'watchers_controller.rb'}
      assert_nil entries.detect {|e| e.name == 'welcome_controller.rb'}
    end
  else
    puts "CVS test repository NOT FOUND. Skipping unit tests !!!"
    def test_fake; assert true end
  end
end
