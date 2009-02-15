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

class IssueTest < Test::Unit::TestCase
  fixtures :projects, :users, :members,
           :trackers, :projects_trackers,
           :issue_statuses, :issue_categories,
           :enumerations,
           :issues,
           :custom_fields, :custom_fields_projects, :custom_fields_trackers, :custom_values,
           :time_entries

  def test_create
    issue = Issue.new(:project_id => 1, :tracker_id => 1, :author_id => 3, :status_id => 1, :priority => Enumeration.priorities.first, :subject => 'test_create', :description => 'IssueTest#test_create', :estimated_hours => '1:30')
    assert issue.save
    issue.reload
    assert_equal 1.5, issue.estimated_hours
  end
  
  def test_create_minimal
    issue = Issue.new(:project_id => 1, :tracker_id => 1, :author_id => 3, :status_id => 1, :priority => Enumeration.priorities.first, :subject => 'test_create')
    assert issue.save
    assert issue.description.nil?
  end
  
  def test_create_with_required_custom_field
    field = IssueCustomField.find_by_name('Database')
    field.update_attribute(:is_required, true)
    
    issue = Issue.new(:project_id => 1, :tracker_id => 1, :author_id => 1, :status_id => 1, :subject => 'test_create', :description => 'IssueTest#test_create_with_required_custom_field')
    assert issue.available_custom_fields.include?(field)
    # No value for the custom field
    assert !issue.save
    assert_equal 'activerecord_error_invalid', issue.errors.on(:custom_values)
    # Blank value
    issue.custom_field_values = { field.id => '' }
    assert !issue.save
    assert_equal 'activerecord_error_invalid', issue.errors.on(:custom_values)
    # Invalid value
    issue.custom_field_values = { field.id => 'SQLServer' }
    assert !issue.save
    assert_equal 'activerecord_error_invalid', issue.errors.on(:custom_values)
    # Valid value
    issue.custom_field_values = { field.id => 'PostgreSQL' }
    assert issue.save
    issue.reload
    assert_equal 'PostgreSQL', issue.custom_value_for(field).value
  end
  
  def test_update_issue_with_required_custom_field
    field = IssueCustomField.find_by_name('Database')
    field.update_attribute(:is_required, true)
    
    issue = Issue.find(1)
    assert_nil issue.custom_value_for(field)
    assert issue.available_custom_fields.include?(field)
    # No change to custom values, issue can be saved
    assert issue.save
    # Blank value
    issue.custom_field_values = { field.id => '' }
    assert !issue.save
    # Valid value
    issue.custom_field_values = { field.id => 'PostgreSQL' }
    assert issue.save
    issue.reload
    assert_equal 'PostgreSQL', issue.custom_value_for(field).value
  end
  
  def test_should_not_update_attributes_if_custom_fields_validation_fails
    issue = Issue.find(1)
    field = IssueCustomField.find_by_name('Database')
    assert issue.available_custom_fields.include?(field)
    
    issue.custom_field_values = { field.id => 'Invalid' }
    issue.subject = 'Should be not be saved'
    assert !issue.save
    
    issue.reload
    assert_equal "Can't print recipes", issue.subject
  end
  
  def test_should_not_recreate_custom_values_objects_on_update
    field = IssueCustomField.find_by_name('Database')
    
    issue = Issue.find(1)
    issue.custom_field_values = { field.id => 'PostgreSQL' }
    assert issue.save
    custom_value = issue.custom_value_for(field)
    issue.reload
    issue.custom_field_values = { field.id => 'MySQL' }
    assert issue.save
    issue.reload
    assert_equal custom_value.id, issue.custom_value_for(field).id
  end
  
  def test_category_based_assignment
    issue = Issue.create(:project_id => 1, :tracker_id => 1, :author_id => 3, :status_id => 1, :priority => Enumeration.priorities.first, :subject => 'Assignment test', :description => 'Assignment test', :category_id => 1)
    assert_equal IssueCategory.find(1).assigned_to, issue.assigned_to
  end
  
  def test_copy
    issue = Issue.new.copy_from(1)
    assert issue.save
    issue.reload
    orig = Issue.find(1)
    assert_equal orig.subject, issue.subject
    assert_equal orig.tracker, issue.tracker
    assert_equal orig.custom_values.first.value, issue.custom_values.first.value
  end
  
  def test_should_close_duplicates
    # Create 3 issues
    issue1 = Issue.new(:project_id => 1, :tracker_id => 1, :author_id => 1, :status_id => 1, :priority => Enumeration.priorities.first, :subject => 'Duplicates test', :description => 'Duplicates test')
    assert issue1.save
    issue2 = issue1.clone
    assert issue2.save
    issue3 = issue1.clone
    assert issue3.save
    
    # 2 is a dupe of 1
    IssueRelation.create(:issue_from => issue2, :issue_to => issue1, :relation_type => IssueRelation::TYPE_DUPLICATES)
    # And 3 is a dupe of 2
    IssueRelation.create(:issue_from => issue3, :issue_to => issue2, :relation_type => IssueRelation::TYPE_DUPLICATES)
    # And 3 is a dupe of 1 (circular duplicates)
    IssueRelation.create(:issue_from => issue3, :issue_to => issue1, :relation_type => IssueRelation::TYPE_DUPLICATES)
        
    assert issue1.reload.duplicates.include?(issue2)
    
    # Closing issue 1
    issue1.init_journal(User.find(:first), "Closing issue1")
    issue1.status = IssueStatus.find :first, :conditions => {:is_closed => true}
    assert issue1.save
    # 2 and 3 should be also closed
    assert issue2.reload.closed?
    assert issue3.reload.closed?    
  end
  
  def test_should_not_close_duplicated_issue
    # Create 3 issues
    issue1 = Issue.new(:project_id => 1, :tracker_id => 1, :author_id => 1, :status_id => 1, :priority => Enumeration.priorities.first, :subject => 'Duplicates test', :description => 'Duplicates test')
    assert issue1.save
    issue2 = issue1.clone
    assert issue2.save
    
    # 2 is a dupe of 1
    IssueRelation.create(:issue_from => issue2, :issue_to => issue1, :relation_type => IssueRelation::TYPE_DUPLICATES)
    # 2 is a dup of 1 but 1 is not a duplicate of 2
    assert !issue2.reload.duplicates.include?(issue1)
    
    # Closing issue 2
    issue2.init_journal(User.find(:first), "Closing issue2")
    issue2.status = IssueStatus.find :first, :conditions => {:is_closed => true}
    assert issue2.save
    # 1 should not be also closed
    assert !issue1.reload.closed?
  end
  
  def test_move_to_another_project_with_same_category
    issue = Issue.find(1)
    assert issue.move_to(Project.find(2))
    issue.reload
    assert_equal 2, issue.project_id
    # Category changes
    assert_equal 4, issue.category_id
    # Make sure time entries were move to the target project
    assert_equal 2, issue.time_entries.first.project_id
  end
  
  def test_move_to_another_project_without_same_category
    issue = Issue.find(2)
    assert issue.move_to(Project.find(2))
    issue.reload
    assert_equal 2, issue.project_id
    # Category cleared
    assert_nil issue.category_id
  end
  
  def test_copy_to_the_same_project
    issue = Issue.find(1)
    copy = nil
    assert_difference 'Issue.count' do
      copy = issue.move_to(issue.project, nil, :copy => true)
    end
    assert_kind_of Issue, copy
    assert_equal issue.project, copy.project
    assert_equal "125", copy.custom_value_for(2).value
  end
  
  def test_copy_to_another_project_and_tracker
    issue = Issue.find(1)
    copy = nil
    assert_difference 'Issue.count' do
      copy = issue.move_to(Project.find(3), Tracker.find(2), :copy => true)
    end
    assert_kind_of Issue, copy
    assert_equal Project.find(3), copy.project
    assert_equal Tracker.find(2), copy.tracker
    # Custom field #2 is not associated with target tracker
    assert_nil copy.custom_value_for(2)
  end
  
  def test_issue_destroy
    Issue.find(1).destroy
    assert_nil Issue.find_by_id(1)
    assert_nil TimeEntry.find_by_issue_id(1)
  end
  
  def test_overdue
    assert Issue.new(:due_date => 1.day.ago.to_date).overdue?
    assert !Issue.new(:due_date => Date.today).overdue?
    assert !Issue.new(:due_date => 1.day.from_now.to_date).overdue?
    assert !Issue.new(:due_date => nil).overdue?
    assert !Issue.new(:due_date => 1.day.ago.to_date, :status => IssueStatus.find(:first, :conditions => {:is_closed => true})).overdue?
  end
end
