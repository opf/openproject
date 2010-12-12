# redMine - project management software
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

require File.expand_path('../../test_helper', __FILE__)

class EnumerationTest < ActiveSupport::TestCase
  fixtures :enumerations, :issues, :custom_fields, :custom_values

  def setup
  end
  
  def test_objects_count
    # low priority
    assert_equal 6, Enumeration.find(4).objects_count
    # urgent
    assert_equal 0, Enumeration.find(7).objects_count
  end
  
  def test_in_use
    # low priority
    assert Enumeration.find(4).in_use?
    # urgent
    assert !Enumeration.find(7).in_use?
  end
  
  def test_default
    e = Enumeration.default
    assert e.is_a?(Enumeration)
    assert e.is_default?
    assert_equal 'Default Enumeration', e.name
  end
  
  def test_create
    e = Enumeration.new(:name => 'Not default', :is_default => false)
    e.type = 'Enumeration'
    assert e.save
    assert_equal 'Default Enumeration', Enumeration.default.name
  end
  
  def test_create_as_default
    e = Enumeration.new(:name => 'Very urgent', :is_default => true)
    e.type = 'Enumeration'
    assert e.save
    assert_equal e, Enumeration.default
  end
  
  def test_update_default
    e = Enumeration.default
    e.update_attributes(:name => 'Changed', :is_default => true)
    assert_equal e, Enumeration.default
  end
  
  def test_update_default_to_non_default
    e = Enumeration.default
    e.update_attributes(:name => 'Changed', :is_default => false)
    assert_nil Enumeration.default
  end
  
  def test_change_default
    e = Enumeration.find_by_name('Default Enumeration')
    e.update_attributes(:name => 'Changed Enumeration', :is_default => true)
    assert_equal e, Enumeration.default
  end
  
  def test_destroy_with_reassign
    Enumeration.find(4).destroy(Enumeration.find(6))
    assert_nil Issue.find(:first, :conditions => {:priority_id => 4})
    assert_equal 6, Enumeration.find(6).objects_count
  end

  def test_should_be_customizable
    assert Enumeration.included_modules.include?(Redmine::Acts::Customizable::InstanceMethods)
  end

  def test_should_belong_to_a_project
    association = Enumeration.reflect_on_association(:project)
    assert association, "No Project association found"
    assert_equal :belongs_to, association.macro
  end

  def test_should_act_as_tree
    enumeration = Enumeration.find(4)

    assert enumeration.respond_to?(:parent)
    assert enumeration.respond_to?(:children)
  end

  def test_is_override
    # Defaults to off
    enumeration = Enumeration.find(4)
    assert !enumeration.is_override?

    # Setup as an override
    enumeration.parent = Enumeration.find(5)
    assert enumeration.is_override?
  end
end
