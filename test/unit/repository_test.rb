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
  fixtures :projects, :repositories, :issues, :issue_statuses, :changesets
  
  def test_create
    repository = Repository.new(:project => Project.find(2))
    assert !repository.save
  
    repository.url = "svn://localhost"
    assert repository.save
    repository.reload
    
    project = Project.find(2)
    assert_equal repository, project.repository
  end

  def test_cant_change_url
    repository = Project.find(1).repository
    url = repository.url
    repository.url = "svn://anotherhost"
    assert_equal  url, repository.url
  end
  
  def test_scan_changesets_for_issue_ids
    # choosing a status to apply to fix issues
    Setting.commit_fix_status_id = IssueStatus.find(:first, :conditions => ["is_closed = ?", true]).id
    
    # make sure issue 1 is not already closed
    assert !Issue.find(1).status.is_closed?
        
    Repository.scan_changesets_for_issue_ids
    assert_equal [101, 102], Issue.find(3).changeset_ids
    
    # fixed issues
    assert Issue.find(1).status.is_closed?
    assert_equal [101], Issue.find(1).changeset_ids
    
    # ignoring commits referencing an issue of another project
    assert_equal [], Issue.find(4).changesets
  end
end
