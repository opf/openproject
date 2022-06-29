#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2022 the OpenProject GmbH
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

describe Version, type: :model do
  fixtures :all

  it 'creates' do
    (v = Version.new.tap do |v|
      v.attributes = { project: Project.find(1), name: '1.1', effective_date: '2011-03-25' }
    end)
    assert v.save
    assert_equal 'open', v.status
  end

  it 'invalids effective date validation' do
    (v = Version.new.tap do |v|
      v.attributes = { project: Project.find(1), name: '1.1', effective_date: '99999-01-01' }
    end)
    assert !v.save
    assert_includes v.errors[:effective_date], I18n.t('activerecord.errors.messages.not_a_date')
  end

  describe '#start_date' do
    context 'with a value saved' do
      it 'is the value' do
        project = Project.find(1)
        (v = Version.new.tap do |v|
          v.attributes = { project:, name: 'Progress', start_date: '2010-01-05' }
        end).save!

        add_work_package(v, estimated_hours: 10, start_date: '2010-03-01')

        assert_equal '2010-01-05', v.start_date.to_s
      end
    end
  end

  it 'progresses should be 0 with no assigned issues' do
    project = Project.find(1)
    (v = Version.new.tap do |v|
      v.attributes = { project:, name: 'Progress' }
    end).save!
    assert_equal 0, v.completed_percent
    assert_equal 0, v.closed_percent
  end

  it 'progresses should be 0 with unbegun assigned issues' do
    project = Project.find(1)
    (v = Version.new.tap do |v|
      v.attributes = { project:, name: 'Progress' }
    end).save!
    add_work_package(v)
    add_work_package(v, done_ratio: 0)
    assert_progress_equal 0, v.completed_percent
    assert_progress_equal 0, v.closed_percent
  end

  it 'progresses should be 100 with closed assigned issues' do
    project = Project.find(1)
    status = Status.where(is_closed: true).first
    (v = Version.new.tap do |v|
      v.attributes = { project:, name: 'Progress' }
    end).save!
    add_work_package(v, status:)
    add_work_package(v, status:, done_ratio: 20)
    add_work_package(v, status:, done_ratio: 70, estimated_hours: 25)
    add_work_package(v, status:, estimated_hours: 15)
    assert_progress_equal 100.0, v.completed_percent
    assert_progress_equal 100.0, v.closed_percent
  end

  it 'progresses should consider done ratio of open assigned issues' do
    project = Project.find(1)
    (v = Version.new.tap do |v|
      v.attributes = { project:, name: 'Progress' }
    end).save!
    add_work_package(v)
    add_work_package(v, done_ratio: 20)
    add_work_package(v, done_ratio: 70)
    assert_progress_equal (0.0 + 20.0 + 70.0) / 3, v.completed_percent
    assert_progress_equal 0, v.closed_percent
  end

  it 'progresses should consider closed issues as completed' do
    project = Project.find(1)
    (v = Version.new.tap do |v|
      v.attributes = { project:, name: 'Progress' }
    end).save!
    add_work_package(v)
    add_work_package(v, done_ratio: 20)
    add_work_package(v, status: Status.where(is_closed: true).first)
    assert_progress_equal (0.0 + 20.0 + 100.0) / 3, v.completed_percent
    assert_progress_equal 100.0 / 3, v.closed_percent
  end

  it 'progresses should consider estimated hours to weight issues' do
    project = Project.find(1)
    (v = Version.new.tap do |v|
      v.attributes = { project:, name: 'Progress' }
    end).save!
    add_work_package(v, estimated_hours: 10)
    add_work_package(v, estimated_hours: 20, done_ratio: 30)
    add_work_package(v, estimated_hours: 40, done_ratio: 10)
    add_work_package(v, estimated_hours: 25, status: Status.where(is_closed: true).first)
    assert_progress_equal ((10.0 * 0) + (20.0 * 0.3) + (40 * 0.1) + (25.0 * 1)) / 95.0 * 100, v.completed_percent
    assert_progress_equal 25.0 / 95.0 * 100, v.closed_percent
  end

  it 'progresses should consider average estimated hours to weight unestimated issues' do
    project = Project.find(1)
    (v = Version.new.tap do |v|
      v.attributes = { project:, name: 'Progress' }
    end).save!
    add_work_package(v, done_ratio: 20)
    add_work_package(v, status: Status.where(is_closed: true).first)
    add_work_package(v, estimated_hours: 10, done_ratio: 30)
    add_work_package(v, estimated_hours: 40, done_ratio: 10)
    assert_progress_equal ((25.0 * 0.2) + (25.0 * 1) + (10.0 * 0.3) + (40.0 * 0.1)) / 100.0 * 100, v.completed_percent
    assert_progress_equal 25.0 / 100.0 * 100, v.closed_percent
  end

  describe '#estimated_hours' do
    before do
      (@version = Version.new.tap do |v|
        v.attributes = { project_id: 1, name: '#estimated_hours' }
      end).save!
    end

    it 'returns 0 with no assigned issues' do
      assert_equal 0, @version.estimated_hours
    end

    it 'returns 0 with no estimated hours' do
      add_work_package(@version)
      assert_equal 0, @version.estimated_hours
    end

    it 'returns the sum of estimated hours' do
      add_work_package(@version, estimated_hours: 2.5)
      add_work_package(@version, estimated_hours: 5)
      assert_equal 7.5, @version.estimated_hours
    end

    it 'returns the sum of leaves estimated hours' do
      parent = add_work_package(@version)
      add_work_package(@version, estimated_hours: 2.5, parent_id: parent.id)
      add_work_package(@version, estimated_hours: 5, parent_id: parent.id)
      assert_equal 7.5, @version.estimated_hours
    end
  end

  private

  def add_work_package(version, attributes = {})
    WorkPackage.create!({ project: version.project,
                          priority_id: 5,
                          status_id: 1,
                          version:,
                          subject: 'Test',
                          author: User.first,
                          type: version.project.types.first }.merge(attributes))
  end

  def assert_progress_equal(expected_float, actual_float, _message = '')
    assert_in_delta(expected_float, actual_float, 0.000001, '')
  end
end
