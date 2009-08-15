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

require File.dirname(__FILE__) + '/../test_helper'

class RepositoryGitTest < Test::Unit::TestCase
  fixtures :projects
  
  # No '..' in the repository path
  REPOSITORY_PATH = RAILS_ROOT.gsub(%r{config\/\.\.}, '') + '/tmp/test/git_repository'
  REPOSITORY_PATH.gsub!(/\//, "\\") if Redmine::Platform.mswin?
  
  def setup
    @project = Project.find(1)
    assert @repository = Repository::Git.create(:project => @project, :url => REPOSITORY_PATH)
  end
  
  if File.directory?(REPOSITORY_PATH)  
    def test_fetch_changesets_from_scratch
      @repository.fetch_changesets
      @repository.reload
      
      assert_equal 12, @repository.changesets.count
      assert_equal 20, @repository.changes.count
      
      commit = @repository.changesets.find(:first, :order => 'committed_on ASC')
      assert_equal "Initial import.\nThe repository contains 3 files.", commit.comments
      assert_equal "jsmith <jsmith@foo.bar>", commit.committer
      assert_equal User.find_by_login('jsmith'), commit.user
      # TODO: add a commit with commit time <> author time to the test repository
      assert_equal "2007-12-14 09:22:52".to_time, commit.committed_on
      assert_equal "2007-12-14".to_date, commit.commit_date
      assert_equal "7234cb2750b63f47bff735edc50a1c0a433c2518", commit.revision
      assert_equal "7234cb2750b63f47bff735edc50a1c0a433c2518", commit.scmid
      assert_equal 3, commit.changes.count
      change = commit.changes.sort_by(&:path).first
      assert_equal "README", change.path
      assert_equal "A", change.action
    end
    
    def test_fetch_changesets_incremental
      @repository.fetch_changesets
      # Remove the 3 latest changesets
      @repository.changesets.find(:all, :order => 'committed_on DESC', :limit => 3).each(&:destroy)
      @repository.reload
      assert_equal 9, @repository.changesets.count
      
      @repository.fetch_changesets
      assert_equal 12, @repository.changesets.count
    end
  else
    puts "Git test repository NOT FOUND. Skipping unit tests !!!"
    def test_fake; assert true end
  end
end
