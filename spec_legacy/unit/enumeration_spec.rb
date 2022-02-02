#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2021 the OpenProject GmbH
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
# See COPYRIGHT and LICENSE files for more details.
#++
require_relative './../legacy_spec_helper'

describe Enumeration, type: :model do
  before do
    WorkPackage.delete_all
    @low_priority = create :priority_low
    @issues = create_list :work_package, 6, priority: @low_priority
    @default_enumeration = create :default_enumeration
  end

  it 'should in use' do
    assert @low_priority.in_use?
    assert !create(:priority).in_use?
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
    @default_enumeration.update(name: 'Changed', is_default: true)
    assert_equal @default_enumeration, Enumeration.default
  end

  it 'should update default to non default' do
    @default_enumeration.update(name: 'Changed', is_default: false)
    assert_nil Enumeration.default
  end

  it 'should change default' do
    e = Enumeration.find_by(name: @default_enumeration.name)
    e.update(name: 'Changed Enumeration', is_default: true)
    assert_equal e, Enumeration.default
  end

  it 'should destroy with reassign' do
    new_priority = create :priority
    Enumeration.find(@low_priority.id).destroy(new_priority)
    assert_nil WorkPackage.find_by(priority_id: @low_priority.id)
    assert_equal @issues.size, new_priority.objects_count
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
end
