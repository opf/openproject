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

describe 'ProjectNestedSet', type: :model do
  context 'nested set' do
    before do
      FactoryGirl.create(:type_standard)
      Project.delete_all

      @a = Project.create!(name: 'Project A', identifier: 'projecta')
      @a1 = Project.create!(name: 'Project A1', identifier: 'projecta1')
      @a1.set_parent!(@a)
      @a2 = Project.create!(name: 'Project A2', identifier: 'projecta2')
      @a2.set_parent!(@a)

      @b = Project.create!(name: 'Project B', identifier: 'projectb')
      @b1 = Project.create!(name: 'Project B1', identifier: 'projectb1')
      @b1.set_parent!(@b)
      @b11 = Project.create!(name: 'Project B11', identifier: 'projectb11')
      @b11.set_parent!(@b1)
      @b2 = Project.create!(name: 'Project B2', identifier: 'projectb2')
      @b2.set_parent!(@b)

      @c = Project.create!(name: 'Project C', identifier: 'projectc')
      @c1 = Project.create!(name: 'Project C1', identifier: 'projectc1')
      @c1.set_parent!(@c)

      [@a, @a1, @a2, @b, @b1, @b11, @b2, @c, @c1].each(&:reload)
    end

    context '#create' do
      it 'should build valid tree' do
        assert_nested_set_values(
          @a   => [nil,   1,  6],
          @a1  => [@a.id, 2,  3],
          @a2  => [@a.id, 4,  5],
          @b   => [nil,   7, 14],
          @b1  => [@b.id, 8, 11],
          @b11 => [@b1.id, 9, 10],
          @b2  => [@b.id, 12, 13],
          @c   => [nil,  15, 18],
          @c1  => [@c.id, 16, 17]
        )
      end
    end

    context '#set_parent!' do
      it 'should keep valid tree' do
        assert_no_difference 'Project.count' do
          Project.find_by_name('Project B1').set_parent!(Project.find_by_name('Project A2'))
        end
        assert_nested_set_values(
          @a   => [nil,   1, 10],
          @a2  => [@a.id, 4,  9],
          @b1  => [@a2.id, 5,  8],
          @b11 => [@b1.id, 6,  7],
          @b   => [nil,  11, 14],
          @c   => [nil,  15, 18]
        )
      end
    end

    context '#destroy' do
      context 'a root with children' do
        it 'should not mess up the tree' do
          assert_difference 'Project.count', -4 do
            Project.find_by_name('Project B').destroy
          end
          assert_nested_set_values(
            @a  => [nil,   1,  6],
            @a1 => [@a.id, 2,  3],
            @a2 => [@a.id, 4,  5],
            @c  => [nil,   7, 10],
            @c1 => [@c.id, 8,  9]
          )
        end
      end

      context 'a child with children' do
        it 'should not mess up the tree' do
          assert_difference 'Project.count', -2 do
            Project.find_by_name('Project B1').destroy
          end
          assert_nested_set_values(
            @a  => [nil,   1,  6],
            @b  => [nil,   7, 10],
            @b2 => [@b.id, 8,  9],
            @c  => [nil,  11, 14]
          )
        end
      end
    end
  end

  def assert_nested_set_values(h)
    assert Project.valid?
    h.each do |project, expected|
      project.reload
      assert_equal expected, [project.parent_id, project.lft, project.rgt], "Unexpected nested set values for #{project.name}"
    end
  end
end
