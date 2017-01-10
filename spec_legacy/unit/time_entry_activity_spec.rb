#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
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
#
# See doc/COPYRIGHT.rdoc for more details.
#++
require 'legacy_spec_helper'

describe TimeEntryActivity, type: :model do
  include MiniTest::Assertions # refute

  fixtures :all

  it 'should be an enumeration' do
    assert TimeEntryActivity.ancestors.include?(Enumeration)
  end

  it 'should objects count' do
    assert_equal 3, TimeEntryActivity.find_by(name: 'Design').objects_count
    assert_equal 1, TimeEntryActivity.find_by(name: 'Development').objects_count
  end

  it 'should option name' do
    assert_equal :enumeration_activities, TimeEntryActivity.new.option_name
  end

  it 'should create with custom field' do
    field = TimeEntryActivityCustomField.find_by(name: 'Billable')
    e = TimeEntryActivity.new(name: 'Custom Data')
    e.custom_field_values = { field.id => '1' }
    assert e.save

    e.reload
    assert_equal 't', e.custom_value_for(field).value
  end

  it 'should create without required custom field should fail' do
    field = TimeEntryActivityCustomField.find_by(name: 'Billable')
    field.update_attribute(:is_required, true)

    e = TimeEntryActivity.new(name: 'Custom Data')
    assert !e.save
    assert_includes e.errors["custom_field_#{field.id}"],
                    I18n.translate('activerecord.errors.messages.blank')
  end

  it 'should create with required custom field should succeed' do
    field = TimeEntryActivityCustomField.find_by(name: 'Billable')
    field.update_attribute(:is_required, true)

    e = TimeEntryActivity.new(name: 'Custom Data')
    e.custom_field_values = { field.id => '1' }
    assert e.save
  end

  it 'should update issue with required custom field change' do
    field = TimeEntryActivityCustomField.find_by(name: 'Billable')
    field.update_attribute(:is_required, true)

    e = TimeEntryActivity.find(10)
    assert e.available_custom_fields.include?(field)
    # No change to custom field, record can be saved
    assert e.save
    # Blanking custom field, save should fail
    e.custom_field_values = { field.id => '' }
    assert !e.save
    refute_empty e.errors["custom_field_#{field.id}"]

    # Update custom field to valid value, save should succeed
    e.custom_field_values = { field.id => '0' }
    assert e.save
    e.reload
    assert_equal 'f', e.custom_value_for(field).value
  end
end
