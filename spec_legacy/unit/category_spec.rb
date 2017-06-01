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

describe Category, type: :model do
  before do
    @project = FactoryGirl.create :project
    @category = FactoryGirl.create :category, project: @project
    @issue = FactoryGirl.create :work_package, project: @project, category: @category
    assert_equal @issue.category, @category
    assert_equal @category.work_packages, [@issue]
  end

  it 'should create' do
    (new_cat = Category.new).attributes = { project_id: @project.id, name: 'New category' }
    assert new_cat.valid?
    assert new_cat.save
    assert_equal 'New category', new_cat.name
  end

  it 'should create with group assignment' do
    group = FactoryGirl.create :group
    role = FactoryGirl.create :role
    (Member.new.tap do |m|
      m.attributes = { principal: group, project: @project, role_ids: [role.id] }
    end).save!
    (new_cat = Category.new).attributes = { project_id: @project.id, name: 'Group assignment', assigned_to_id: group.id }
    assert new_cat.valid?
    assert new_cat.save
    assert_kind_of Group, new_cat.assigned_to
    assert_equal group, new_cat.assigned_to
  end

  # Make sure the category was nullified on the issue
  it 'should destroy' do
    @category.destroy
    assert_nil @issue.reload.category
  end

  # both issue categories must be in the same project
  it 'should destroy with reassign' do
    reassign_to = FactoryGirl.create :category, project: @project
    @category.destroy(reassign_to)
    # Make sure the issue was reassigned
    assert_equal reassign_to, @issue.reload.category
  end
end
