# Redmine - project management software
# Copyright (C) 2006-2008  Jean-Philippe Lang
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

class VersionTest < Test::Unit::TestCase
  fixtures :projects, :users, :issues, :issue_statuses, :trackers, :enumerations, :versions

  def setup
  end
  
  def test_create
    v = Version.new(:project => Project.find(1), :name => '1.1', :effective_date => '2011-03-25')
    assert v.save
  end
  
  def test_invalid_effective_date_validation
    v = Version.new(:project => Project.find(1), :name => '1.1', :effective_date => '99999-01-01')
    assert !v.save
    assert_equal I18n.translate('activerecord.errors.messages.not_a_date'), v.errors.on(:effective_date)
  end
  
  def test_progress_should_be_0_with_no_assigned_issues
    project = Project.find(1)
    v = Version.create!(:project => project, :name => 'Progress')
    assert_equal 0, v.completed_pourcent
    assert_equal 0, v.closed_pourcent
  end
  
  def test_progress_should_be_0_with_unbegun_assigned_issues
    project = Project.find(1)
    v = Version.create!(:project => project, :name => 'Progress')
    add_issue(v)
    add_issue(v, :done_ratio => 0)
    assert_progress_equal 0, v.completed_pourcent
    assert_progress_equal 0, v.closed_pourcent
  end
  
  def test_progress_should_be_100_with_closed_assigned_issues
    project = Project.find(1)
    status = IssueStatus.find(:first, :conditions => {:is_closed => true})
    v = Version.create!(:project => project, :name => 'Progress')
    add_issue(v, :status => status)
    add_issue(v, :status => status, :done_ratio => 20)
    add_issue(v, :status => status, :done_ratio => 70, :estimated_hours => 25)
    add_issue(v, :status => status, :estimated_hours => 15)
    assert_progress_equal 100.0, v.completed_pourcent
    assert_progress_equal 100.0, v.closed_pourcent
  end
  
  def test_progress_should_consider_done_ratio_of_open_assigned_issues
    project = Project.find(1)
    v = Version.create!(:project => project, :name => 'Progress')
    add_issue(v)
    add_issue(v, :done_ratio => 20)
    add_issue(v, :done_ratio => 70)
    assert_progress_equal (0.0 + 20.0 + 70.0)/3, v.completed_pourcent
    assert_progress_equal 0, v.closed_pourcent
  end
  
  def test_progress_should_consider_closed_issues_as_completed
    project = Project.find(1)
    v = Version.create!(:project => project, :name => 'Progress')
    add_issue(v)
    add_issue(v, :done_ratio => 20)
    add_issue(v, :status => IssueStatus.find(:first, :conditions => {:is_closed => true}))
    assert_progress_equal (0.0 + 20.0 + 100.0)/3, v.completed_pourcent
    assert_progress_equal (100.0)/3, v.closed_pourcent
  end
  
  def test_progress_should_consider_estimated_hours_to_weigth_issues
    project = Project.find(1)
    v = Version.create!(:project => project, :name => 'Progress')
    add_issue(v, :estimated_hours => 10)
    add_issue(v, :estimated_hours => 20, :done_ratio => 30)
    add_issue(v, :estimated_hours => 40, :done_ratio => 10)
    add_issue(v, :estimated_hours => 25, :status => IssueStatus.find(:first, :conditions => {:is_closed => true}))
    assert_progress_equal (10.0*0 + 20.0*0.3 + 40*0.1 + 25.0*1)/95.0*100, v.completed_pourcent
    assert_progress_equal 25.0/95.0*100, v.closed_pourcent
  end
  
  def test_progress_should_consider_average_estimated_hours_to_weigth_unestimated_issues
    project = Project.find(1)
    v = Version.create!(:project => project, :name => 'Progress')
    add_issue(v, :done_ratio => 20)
    add_issue(v, :status => IssueStatus.find(:first, :conditions => {:is_closed => true}))
    add_issue(v, :estimated_hours => 10, :done_ratio => 30)
    add_issue(v, :estimated_hours => 40, :done_ratio => 10)
    assert_progress_equal (25.0*0.2 + 25.0*1 + 10.0*0.3 + 40.0*0.1)/100.0*100, v.completed_pourcent
    assert_progress_equal 25.0/100.0*100, v.closed_pourcent
  end
  
  private
  
  def add_issue(version, attributes={})
    Issue.create!({:project => version.project,
                   :fixed_version => version,
                   :subject => 'Test',
                   :author => User.find(:first),
                   :tracker => version.project.trackers.find(:first)}.merge(attributes))
  end
  
  def assert_progress_equal(expected_float, actual_float, message="")
    assert_in_delta(expected_float, actual_float, 0.000001, message="")
  end
end
