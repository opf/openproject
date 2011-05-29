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
require File.expand_path('../../test_helper', __FILE__)

class TimeEntryActivityTest < ActiveSupport::TestCase
  fixtures :enumerations, :time_entries

  def test_should_be_an_enumeration
    assert TimeEntryActivity.ancestors.include?(Enumeration)
  end
  
  def test_objects_count
    assert_equal 3, TimeEntryActivity.find_by_name("Design").objects_count
    assert_equal 1, TimeEntryActivity.find_by_name("Development").objects_count
  end

  def test_option_name
    assert_equal :enumeration_activities, TimeEntryActivity.new.option_name
  end

  def test_create_with_custom_field
    field = TimeEntryActivityCustomField.find_by_name('Billable')
    e = TimeEntryActivity.new(:name => 'Custom Data')
    e.custom_field_values = {field.id => "1"}
    assert e.save

    e.reload
    assert_equal "1", e.custom_value_for(field).value
  end

  def test_create_without_required_custom_field_should_fail
    field = TimeEntryActivityCustomField.find_by_name('Billable')
    field.update_attribute(:is_required, true)

    e = TimeEntryActivity.new(:name => 'Custom Data')
    assert !e.save
    assert_equal I18n.translate('activerecord.errors.messages.invalid'), e.errors.on(:custom_values)
  end

  def test_create_with_required_custom_field_should_succeed
    field = TimeEntryActivityCustomField.find_by_name('Billable')
    field.update_attribute(:is_required, true)

    e = TimeEntryActivity.new(:name => 'Custom Data')
    e.custom_field_values = {field.id => "1"}
    assert e.save
  end

  def test_update_issue_with_required_custom_field_change
    field = TimeEntryActivityCustomField.find_by_name('Billable')
    field.update_attribute(:is_required, true)

    e = TimeEntryActivity.find(10)
    assert e.available_custom_fields.include?(field)
    # No change to custom field, record can be saved
    assert e.save
    # Blanking custom field, save should fail
    e.custom_field_values = {field.id => ""}
    assert !e.save
    assert e.errors.on(:custom_values)
    
    # Update custom field to valid value, save should succeed
    e.custom_field_values = {field.id => "0"}
    assert e.save
    e.reload
    assert_equal "0", e.custom_value_for(field).value
  end

end

