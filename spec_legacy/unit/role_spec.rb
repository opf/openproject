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
require_relative '../legacy_spec_helper'

describe Role, type: :model do
  fixtures :all

  it 'should copy workflows' do
    source = Role.find(1)
    assert_equal 90, source.workflows.size

    target = Role.new(name: 'Target')
    assert target.save
    target.workflows.copy_from_role(source)
    target.reload
    assert_equal 90, target.workflows.size
  end

  it 'should add permission' do
    role = Role.find(1)
    size = role.permissions.size
    role.add_permission!('apermission', 'anotherpermission')
    role.reload
    assert role.permissions.include?(:anotherpermission)
    assert_equal size + 2, role.permissions.size
  end

  it 'should remove permission' do
    role = Role.find(1)
    size = role.permissions.size
    perm = role.permissions[0..1]
    role.remove_permission!(*perm)
    role.reload
    assert !role.permissions.include?(perm[0])
    assert_equal size - 2, role.permissions.size
  end

  context '#anonymous' do
    it 'should return the anonymous role' do
      role = Role.anonymous
      assert role.builtin?
      assert_equal Role::BUILTIN_ANONYMOUS, role.builtin
    end

    context 'with a missing anonymous role' do
      before do
        Role.where("builtin = #{Role::BUILTIN_ANONYMOUS}").delete_all
      end

      it 'should create a new anonymous role' do
        assert_difference('Role.count') do
          Role.anonymous
        end
      end

      it 'should return the anonymous role' do
        role = Role.anonymous
        assert role.builtin?
        assert_equal Role::BUILTIN_ANONYMOUS, role.builtin
      end
    end
  end

  context '#non_member' do
    it 'should return the non-member role' do
      role = Role.non_member
      assert role.builtin?
      assert_equal Role::BUILTIN_NON_MEMBER, role.builtin
    end

    context 'with a missing non-member role' do
      before do
        Role.where("builtin = #{Role::BUILTIN_NON_MEMBER}").delete_all
      end

      it 'should create a new non-member role' do
        assert_difference('Role.count') do
          Role.non_member
        end
      end

      it 'should return the non-member role' do
        role = Role.non_member
        assert role.builtin?
        assert_equal Role::BUILTIN_NON_MEMBER, role.builtin
      end
    end
  end
end
