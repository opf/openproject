#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require_relative '../legacy_spec_helper'

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
    assert_equal 0, Workflow.where(old_status_id: status.id).count
    assert_equal 0, Workflow.where(new_status_id: status.id).count
  end

  it 'should destroy status in use' do
    # Status assigned to an Issue
    status = WorkPackage.find(1).status
    assert_raises(RuntimeError, "Can't delete status") { status.destroy }
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
end
