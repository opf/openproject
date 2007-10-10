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

class RepositoryTest < Test::Unit::TestCase
  fixtures :projects, :repositories, :issues, :issue_statuses, :changesets, :changes
  
  def setup
    @repository = Project.find(1).repository
  end
  
  def test_create
    repository = Repository::Subversion.new(:project => Project.find(2))
    assert !repository.save
  
    repository.url = "svn://localhost"
    assert repository.save
    repository.reload
    
    project = Project.find(2)
    assert_equal repository, project.repository
  end
  
  def test_scan_changesets_for_issue_ids
    # choosing a status to apply to fix issues
    Setting.commit_fix_status_id = IssueStatus.find(:first, :conditions => ["is_closed = ?", true]).id
    Setting.commit_fix_done_ratio = "90"

    # make sure issue 1 is not already closed
    assert !Issue.find(1).status.is_closed?
        
    Repository.scan_changesets_for_issue_ids
    assert_equal [101, 102], Issue.find(3).changeset_ids
    
    # fixed issues
    fixed_issue = Issue.find(1)
    assert fixed_issue.status.is_closed?
    assert_equal 90, fixed_issue.done_ratio
    assert_equal [101], fixed_issue.changeset_ids
    
    # ignoring commits referencing an issue of another project
    assert_equal [], Issue.find(4).changesets
  end
  
  def test_for_changeset_comments_strip
    repository = Repository::Mercurial.create( :project => Project.find( 4 ), :url => '/foo/bar/baz' )
    comment = <<-COMMENT
    This is a loooooooooooooooooooooooooooong comment                                                   
                                                                                                       
                                                                                            
    COMMENT
    changeset = Changeset.new(
      :comments => comment, :commit_date => Time.now, :revision => 0, :scmid => 'f39b7922fb3c',
      :committer => 'foo <foo@example.com>', :committed_on => Time.now, :repository_id => repository )
    assert( changeset.save )
    assert_not_equal( comment, changeset.comments )
    assert_equal( 'This is a loooooooooooooooooooooooooooong comment', changeset.comments )
  end
end
