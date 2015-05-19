#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
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

describe Enumeration, type: :model do
  before do
    WorkPackage.delete_all
    @low_priority = FactoryGirl.create :priority_low
    @issues = FactoryGirl.create_list :work_package, 6, priority: @low_priority
    @default_enumeration = FactoryGirl.create :default_enumeration
  end

  it 'should objects count' do
    assert_equal @issues.size, @low_priority.objects_count
    assert_equal 0, FactoryGirl.create(:priority).objects_count
  end

  it 'should in use' do
    assert @low_priority.in_use?
    assert !FactoryGirl.create(:priority).in_use?
  end

  it 'should default' do
    e = Enumeration.default
    assert e.is_a?(Enumeration)
    assert e.is_default?
    assert_equal 'Default Enumeration', e.name
  end

  it 'should create' do
    e = Enumeration.new(name: 'Not default', is_default: false)
    e.type = 'Enumeration'
    assert e.save
    assert_equal @default_enumeration.name, Enumeration.default.name
  end

  it 'should create as default' do
    e = Enumeration.new(name: 'Very urgent', is_default: true)
    e.type = 'Enumeration'
    assert e.save
    assert_equal e, Enumeration.default
  end

  it 'should update default' do
    @default_enumeration.update_attributes(name: 'Changed', is_default: true)
    assert_equal @default_enumeration, Enumeration.default
  end

  it 'should update default to non default' do
    @default_enumeration.update_attributes(name: 'Changed', is_default: false)
    assert_nil Enumeration.default
  end

  it 'should change default' do
    e = Enumeration.find_by_name(@default_enumeration.name)
    e.update_attributes(name: 'Changed Enumeration', is_default: true)
    assert_equal e, Enumeration.default
  end

  it 'should destroy with reassign' do
    new_priority = FactoryGirl.create :priority
    Enumeration.find(@low_priority).destroy(new_priority)
    assert_nil WorkPackage.find(:first, conditions: { priority_id: @low_priority.id })
    assert_equal @issues.size, new_priority.objects_count
  end

  it 'should be customizable' do
    assert Enumeration.included_modules.include?(Redmine::Acts::Customizable::InstanceMethods)
  end

  it 'should belong to a project' do
    association = Enumeration.reflect_on_association(:project)
    assert association, 'No Project association found'
    assert_equal :belongs_to, association.macro
  end

  it 'should act as tree' do
    assert @low_priority.respond_to?(:parent)
    assert @low_priority.respond_to?(:children)
  end

  it 'should is override' do
    # Defaults to off
    assert !@low_priority.is_override?

    # Setup as an override
    @low_priority.parent = FactoryGirl.create :priority
    assert @low_priority.is_override?
  end
end
