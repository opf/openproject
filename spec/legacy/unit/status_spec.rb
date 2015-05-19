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

describe Status, type: :model do
  fixtures :all

  it 'should create' do
    status = Status.new name: 'Assigned'
    assert !status.save
    # status name uniqueness
    assert_equal 1, status.errors.count

    status.name = 'Test Status'
    assert status.save
    assert !status.is_default
  end

  it 'should destroy' do
    status = Status.find(3)
    assert_difference 'Status.count', -1 do
      assert status.destroy
    end
    assert_nil Workflow.first(conditions: { old_status_id: status.id })
    assert_nil Workflow.first(conditions: { new_status_id: status.id })
  end

  it 'should destroy status in use' do
    # Status assigned to an Issue
    status = WorkPackage.find(1).status
    assert_raise(RuntimeError, "Can't delete status") { status.destroy }
  end

  it 'should default' do
    status = Status.default
    assert_kind_of Status, status
  end

  it 'should change default' do
    status = Status.find(2)
    assert !status.is_default
    status.is_default = true
    assert status.save
    status.reload

    assert_equal status, Status.default
    assert !Status.find(1).is_default
  end

  it 'should reorder should not clear default status' do
    status = Status.default
    status.move_to_bottom
    status.reload
    assert status.is_default?
  end

  context '#update_done_ratios' do
    before do
      @issue = WorkPackage.find(1)
      @status = Status.find(1)
      @status.update_attribute(:default_done_ratio, 50)
    end

    context 'with Setting.work_package_done_ratio using the field' do
      before do
        Setting.work_package_done_ratio = 'field'
      end

      it 'should change nothing' do
        Status.update_work_package_done_ratios

        assert_equal 0, WorkPackage.count(conditions: { done_ratio: 50 })
      end
    end

    context 'with Setting.work_package_done_ratio using the status' do
      before do
        Setting.work_package_done_ratio = 'status'
      end

      it "should update all of the issue's done_ratios to match their Issue Status" do
        Status.update_work_package_done_ratios

        issues = WorkPackage.find([1, 3, 4, 5, 6, 7, 9, 10])
        issues.each do |issue|
          assert_equal @status, issue.status
          assert_equal 50, issue.read_attribute(:done_ratio)
        end
      end
    end
  end
end
