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

class RoleTest < ActiveSupport::TestCase
  fixtures :roles, :workflows

  def test_copy_workflows
    source = Role.find(1)
    assert_equal 90, source.workflows.size
    
    target = Role.new(:name => 'Target')
    assert target.save
    target.workflows.copy(source)
    target.reload
    assert_equal 90, target.workflows.size
  end

  def test_add_permission
    role = Role.find(1)
    size = role.permissions.size
    role.add_permission!("apermission", "anotherpermission")
    role.reload
    assert role.permissions.include?(:anotherpermission)
    assert_equal size + 2, role.permissions.size
  end

  def test_remove_permission
    role = Role.find(1)
    size = role.permissions.size
    perm = role.permissions[0..1]
    role.remove_permission!(*perm)
    role.reload
    assert ! role.permissions.include?(perm[0])
    assert_equal size - 2, role.permissions.size
  end

  context "#anonymous" do
    should "return the anonymous role" do
      role = Role.anonymous
      assert role.builtin?
      assert_equal Role::BUILTIN_ANONYMOUS, role.builtin
    end

    context "with a missing anonymous role" do
      setup do
        Role.delete_all("builtin = #{Role::BUILTIN_ANONYMOUS}")
      end

      should "create a new anonymous role" do
        assert_difference('Role.count') do
          Role.anonymous
        end
      end

      should "return the anonymous role" do
        role = Role.anonymous
        assert role.builtin?
        assert_equal Role::BUILTIN_ANONYMOUS, role.builtin
      end
    end
  end

  context "#non_member" do
    should "return the non-member role" do
      role = Role.non_member
      assert role.builtin?
      assert_equal Role::BUILTIN_NON_MEMBER, role.builtin
    end

    context "with a missing non-member role" do
      setup do
        Role.delete_all("builtin = #{Role::BUILTIN_NON_MEMBER}")
      end

      should "create a new non-member role" do
        assert_difference('Role.count') do
          Role.non_member
        end
      end

      should "return the non-member role" do
        role = Role.non_member
        assert role.builtin?
        assert_equal Role::BUILTIN_NON_MEMBER, role.builtin
      end
    end
  end
end
