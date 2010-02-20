# encoding: utf-8
#
# Redmine - project management software
# Copyright (C) 2006-2010  Jean-Philippe Lang
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

class ChangesetTest < ActiveSupport::TestCase
  fixtures :projects, :repositories, :issues, :issue_statuses, :changesets, :changes, :issue_categories, :enumerations, :custom_fields, :custom_values, :users, :members, :member_roles, :trackers

  def setup
  end
  
  def test_ref_keywords_any
    ActionMailer::Base.deliveries.clear
    Setting.commit_fix_status_id = IssueStatus.find(:first, :conditions => ["is_closed = ?", true]).id
    Setting.commit_fix_done_ratio = '90'
    Setting.commit_ref_keywords = '*'
    Setting.commit_fix_keywords = 'fixes , closes'
    
    c = Changeset.new(:repository => Project.find(1).repository,
                      :committed_on => Time.now,
                      :comments => 'New commit (#2). Fixes #1')
    c.scan_comment_for_issue_ids
    
    assert_equal [1, 2], c.issue_ids.sort
    fixed = Issue.find(1)
    assert fixed.closed?
    assert_equal 90, fixed.done_ratio
    assert_equal 1, ActionMailer::Base.deliveries.size
  end
  
  def test_ref_keywords_any_line_start
    Setting.commit_ref_keywords = '*'

    c = Changeset.new(:repository => Project.find(1).repository,
                      :committed_on => Time.now,
                      :comments => '#1 is the reason of this commit')
    c.scan_comment_for_issue_ids

    assert_equal [1], c.issue_ids.sort
  end

  def test_ref_keywords_allow_brackets_around_a_issue_number
    Setting.commit_ref_keywords = '*'

    c = Changeset.new(:repository => Project.find(1).repository,
                      :committed_on => Time.now,
                      :comments => '[#1] Worked on this issue')
    c.scan_comment_for_issue_ids

    assert_equal [1], c.issue_ids.sort
  end

  def test_ref_keywords_allow_brackets_around_multiple_issue_numbers
    Setting.commit_ref_keywords = '*'

    c = Changeset.new(:repository => Project.find(1).repository,
                      :committed_on => Time.now,
                      :comments => '[#1 #2, #3] Worked on these')
    c.scan_comment_for_issue_ids

    assert_equal [1,2,3], c.issue_ids.sort
  end
  
  def test_commit_referencing_a_subproject_issue
    c = Changeset.new(:repository => Project.find(1).repository,
                      :committed_on => Time.now,
                      :comments => 'refs #5, a subproject issue')
    c.scan_comment_for_issue_ids
    
    assert_equal [5], c.issue_ids.sort
    assert c.issues.first.project != c.project
  end

  def test_commit_referencing_a_parent_project_issue
    # repository of child project
    r = Repository::Subversion.create!(:project => Project.find(3), :url => 'svn://localhost/test')
      
    c = Changeset.new(:repository => r,
                      :committed_on => Time.now,
                      :comments => 'refs #2, an issue of a parent project')
    c.scan_comment_for_issue_ids
    
    assert_equal [2], c.issue_ids.sort
    assert c.issues.first.project != c.project
  end

  def test_previous
    changeset = Changeset.find_by_revision('3')
    assert_equal Changeset.find_by_revision('2'), changeset.previous
  end

  def test_previous_nil
    changeset = Changeset.find_by_revision('1')
    assert_nil changeset.previous
  end

  def test_next
    changeset = Changeset.find_by_revision('2')
    assert_equal Changeset.find_by_revision('3'), changeset.next
  end

  def test_next_nil
    changeset = Changeset.find_by_revision('10')
    assert_nil changeset.next
  end
  
  def test_comments_should_be_converted_to_utf8
    with_settings :commit_logs_encoding => 'ISO-8859-1' do
      c = Changeset.new
      c.comments = File.read("#{RAILS_ROOT}/test/fixtures/encoding/iso-8859-1.txt")
      assert_equal "Texte encodé en ISO-8859-1.", c.comments
    end
  end
  
  def test_invalid_utf8_sequences_in_comments_should_be_stripped
    c = Changeset.new
    c.comments = File.read("#{RAILS_ROOT}/test/fixtures/encoding/iso-8859-1.txt")
    assert_equal "Texte encod en ISO-8859-1.", c.comments
  end
end
