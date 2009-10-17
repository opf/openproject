# redMine - project management software
# Copyright (C) 2006-2009  Jean-Philippe Lang
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

# Test case that checks that the testing infrastructure is setup correctly.
class TestingTest < ActiveSupport::TestCase
  def test_working
    assert true
  end

  test "Rails 'test' case syntax" do
    assert true
  end

  should "work with shoulda" do
    assert true
  end

  context "works with a context" do
    should "work" do
      assert true
    end
  end

end
