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

class CustomValueTest < Test::Unit::TestCase
  fixtures :custom_fields

  def test_float_field
    v = CustomValue.new(:customized => User.find(:first), :custom_field => UserCustomField.find_by_name('Money'))
    v.value = '11.2'
    assert v.save
    v.value = ''
    assert v.save
    v.value = '-6.250'
    assert v.save
    v.value = '6a'
    assert !v.save
  end
  
  def test_default_value
    field = CustomField.find_by_default_value('Default string')
    assert_not_nil field
    
    v = CustomValue.new(:custom_field => field)
    assert_equal 'Default string', v.value

    v = CustomValue.new(:custom_field => field, :value => 'Not empty')
    assert_equal 'Not empty', v.value
  end
end
