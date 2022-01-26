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
require_relative '../legacy_spec_helper'

describe Project, type: :model do
  fixtures :all

  before do
    User.current = nil
  end

  it { is_expected.to validate_presence_of :name }

  context 'associations' do
    it { is_expected.to have_many :members                                       }
    it { is_expected.to have_many(:users).through(:members)                      }
    it { is_expected.to have_many :member_principals                             }
    it { is_expected.to have_many(:principals).through(:member_principals)       }
    it { is_expected.to have_many :enabled_modules                               }
    it { is_expected.to have_many :work_packages                                 }
    it { is_expected.to have_many(:work_package_changes).through(:work_packages) }
    it { is_expected.to have_many :versions                                      }
    it { is_expected.to have_many :time_entries                                  }
    it { is_expected.to have_many :queries                                       }
    it { is_expected.to have_many :news                                          }
    it { is_expected.to have_many :categories                                    }
    it { is_expected.to have_many :forums                                        }
    it { is_expected.to have_many(:changesets).through(:repository)              }

    it { is_expected.to have_one :repository                                     }
    it { is_expected.to have_one :wiki                                           }

    it { is_expected.to have_and_belong_to_many :types                           }
    it { is_expected.to have_and_belong_to_many :work_package_custom_fields      }
  end

  it 'should members should be active users' do
    Project.all.each do |project|
      assert_nil project.members.detect { |m| !(m.principal.is_a?(User) && m.principal.active?) }
    end
  end

  it 'should users should be active users' do
    Project.all.each do |project|
      assert_nil project.users.detect { |u| !(u.is_a?(User) && u.active?) }
    end
  end

  it 'should parent' do
    p = Project.find(6).parent
    assert p.is_a?(Project)
    assert_equal 5, p.id
  end

  it 'should ancestors' do
    a = Project.find(6).ancestors
    assert a.first.is_a?(Project)
    assert_equal [1, 5], a.map(&:id).sort
  end

  it 'should root' do
    r = Project.find(6).root
    assert r.is_a?(Project)
    assert_equal 1, r.id
  end

  it 'should children' do
    c = Project.find(1).children
    assert c.first.is_a?(Project)
    # ignore ordering, since it depends on database collation configuration
    # and may order lowercase/uppercase chars in a different order
    assert_equal [3, 4, 5], c.map(&:id).sort!
  end

  it 'should descendants' do
    d = Project.find(1).descendants.pluck(:id)
    assert_equal [3, 4, 5, 6], d.sort
  end

  it 'should users by role' do
    users_by_role = Project.find(1).users_by_role
    assert_kind_of Hash, users_by_role
    role = Role.find(1)
    assert_kind_of Array, users_by_role[role]
    assert users_by_role[role].include?(User.find(2))
  end

  it 'should rolled up types' do
    parent = Project.find(1)
    parent.types = ::Type.find([1, 2])
    child = parent.children.find(3)

    assert_equal [1, 2], parent.type_ids
    assert_equal [2, 3], child.types.map(&:id)

    assert_kind_of ::Type, parent.rolled_up_types.first

    assert_equal [999, 1, 2, 3], parent.rolled_up_types.map(&:id)
    assert_equal [2, 3], child.rolled_up_types.map(&:id)
  end

  it 'should rolled up types should ignore archived subprojects' do
    parent = Project.find(1)
    parent.types = ::Type.find([1, 2])
    child = parent.children.find(3)
    child.types = ::Type.find([1, 3])
    parent.children.each do |child|
      child.update(active: false)
      child.children.each do |grand_child|
        grand_child.update(active: false)
      end
    end

    assert_equal [1, 2], parent.rolled_up_types.map(&:id)
  end

  context 'with modules',
          with_settings: { default_projects_modules: ['work_package_tracking', 'repository'] } do
    it 'should enabled module names' do
      project = Project.new

      project.enabled_module_names = %w(work_package_tracking news)
      assert_equal %w(news work_package_tracking), project.enabled_module_names.sort
    end
  end

  it 'should enabled module names should not recreate enabled modules' do
    project = Project.find(1)
    # Remove one module
    modules = project.enabled_modules.to_a.slice(0..-2)
    assert modules.any?
    assert_difference 'EnabledModule.count', -1 do
      project.enabled_module_names = modules.map(&:name)
    end
    project.reload
    # Ids should be preserved
    assert_equal project.enabled_module_ids.sort, modules.map(&:id).sort
  end

  it 'should close completed versions' do
    Version.update_all("status = 'open'")
    project = Project.find(1)
    refute_nil project.versions.detect { |v| v.completed? && v.status == 'open' }
    refute_nil project.versions.detect { |v| !v.completed? && v.status == 'open' }
    project.close_completed_versions
    project.reload
    assert_nil project.versions.detect { |v| v.completed? && v.status != 'closed' }
    refute_nil project.versions.detect { |v| !v.completed? && v.status == 'open' }
  end
end
