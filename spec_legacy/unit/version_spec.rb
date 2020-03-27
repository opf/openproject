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

describe Version, type: :model do
  fixtures :all

  it 'should create' do
    (v = Version.new.tap do |v|
      v.attributes = { project: Project.find(1), name: '1.1', effective_date: '2011-03-25' }
    end)
    assert v.save
    assert_equal 'open', v.status
  end

  it 'should invalid effective date validation' do
    (v = Version.new.tap do |v|
      v.attributes = { project: Project.find(1), name: '1.1', effective_date: '99999-01-01' }
    end)
    assert !v.save
    assert_includes v.errors[:effective_date], I18n.translate('activerecord.errors.messages.not_a_date')
  end

  context '#start_date' do
    context 'with a value saved' do
      it 'should be the value' do
        project = Project.find(1)
        (v = Version.new.tap do |v|
          v.attributes = { project: project, name: 'Progress', start_date: '2010-01-05' }
        end).save!

        add_work_package(v, estimated_hours: 10, start_date: '2010-03-01')

        assert_equal '2010-01-05', v.start_date.to_s
      end
    end
  end

  it 'should progress should be 0 with no assigned issues' do
    project = Project.find(1)
    (v = Version.new.tap do |v|
      v.attributes = { project: project, name: 'Progress' }
    end).save!
    assert_equal 0, v.completed_percent
    assert_equal 0, v.closed_percent
  end

  it 'should progress should be 0 with unbegun assigned issues' do
    project = Project.find(1)
    (v = Version.new.tap do |v|
      v.attributes = { project: project, name: 'Progress' }
    end).save!
    add_work_package(v)
    add_work_package(v, done_ratio: 0)
    assert_progress_equal 0, v.completed_percent
    assert_progress_equal 0, v.closed_percent
  end

  it 'should progress should be 100 with closed assigned issues' do
    project = Project.find(1)
    status = Status.where(is_closed: true).first
    (v = Version.new.tap do |v|
      v.attributes = { project: project, name: 'Progress' }
    end).save!
    add_work_package(v, status: status)
    add_work_package(v, status: status, done_ratio: 20)
    add_work_package(v, status: status, done_ratio: 70, estimated_hours: 25)
    add_work_package(v, status: status, estimated_hours: 15)
    assert_progress_equal 100.0, v.completed_percent
    assert_progress_equal 100.0, v.closed_percent
  end

  it 'should progress should consider done ratio of open assigned issues' do
    project = Project.find(1)
    (v = Version.new.tap do |v|
      v.attributes = { project: project, name: 'Progress' }
    end).save!
    add_work_package(v)
    add_work_package(v, done_ratio: 20)
    add_work_package(v, done_ratio: 70)
    assert_progress_equal (0.0 + 20.0 + 70.0) / 3, v.completed_percent
    assert_progress_equal 0, v.closed_percent
  end

  it 'should progress should consider closed issues as completed' do
    project = Project.find(1)
    (v = Version.new.tap do |v|
      v.attributes = { project: project, name: 'Progress' }
    end).save!
    add_work_package(v)
    add_work_package(v, done_ratio: 20)
    add_work_package(v, status: Status.where(is_closed: true).first)
    assert_progress_equal (0.0 + 20.0 + 100.0) / 3, v.completed_percent
    assert_progress_equal (100.0) / 3, v.closed_percent
  end

  it 'should progress should consider estimated hours to weigth issues' do
    project = Project.find(1)
    (v = Version.new.tap do |v|
      v.attributes = { project: project, name: 'Progress' }
    end).save!
    add_work_package(v, estimated_hours: 10)
    add_work_package(v, estimated_hours: 20, done_ratio: 30)
    add_work_package(v, estimated_hours: 40, done_ratio: 10)
    add_work_package(v, estimated_hours: 25, status: Status.where(is_closed: true).first)
    assert_progress_equal (10.0 * 0 + 20.0 * 0.3 + 40 * 0.1 + 25.0 * 1) / 95.0 * 100, v.completed_percent
    assert_progress_equal 25.0 / 95.0 * 100, v.closed_percent
  end

  it 'should progress should consider average estimated hours to weigth unestimated issues' do
    project = Project.find(1)
    (v = Version.new.tap do |v|
      v.attributes = { project: project, name: 'Progress' }
    end).save!
    add_work_package(v, done_ratio: 20)
    add_work_package(v, status: Status.where(is_closed: true).first)
    add_work_package(v, estimated_hours: 10, done_ratio: 30)
    add_work_package(v, estimated_hours: 40, done_ratio: 10)
    assert_progress_equal (25.0 * 0.2 + 25.0 * 1 + 10.0 * 0.3 + 40.0 * 0.1) / 100.0 * 100, v.completed_percent
    assert_progress_equal 25.0 / 100.0 * 100, v.closed_percent
  end

  context '#behind_schedule?' do
    before do
      ProjectCustomField.destroy_all # Custom values are a mess to isolate in tests
      @project = FactoryBot.create(:project, identifier: 'test0')
      @project.types << FactoryBot.create(:type)

      (@version = Version.new.tap do |v|
        v.attributes = { project: @project, effective_date: nil, name: 'test' }
      end).save!
    end

    it 'should be false if there are no issues assigned' do
      @version.update_attribute(:effective_date, Date.yesterday)
      assert_equal false, @version.behind_schedule?
    end

    it 'should be false if there is no effective_date' do
      assert_equal false, @version.behind_schedule?
    end

    it 'should be false if all of the issues are ahead of schedule' do
      @version.update_attribute(:effective_date, 7.days.from_now.to_date)
      @version.work_packages = [
        FactoryBot.create(:work_package, project: @project, start_date: 7.days.ago, done_ratio: 60), # 14 day span, 60% done, 50% time left
        FactoryBot.create(:work_package, project: @project, start_date: 7.days.ago, done_ratio: 60) # 14 day span, 60% done, 50% time left
      ]
      assert_equal 60, @version.completed_percent
      assert_equal false, @version.behind_schedule?
    end

    it 'should be true if any of the issues are behind schedule' do
      @version.update_attribute(:start_date, 7.days.ago.to_date)
      @version.update_attribute(:effective_date, 7.days.from_now.to_date)
      @version.work_packages = [
        FactoryBot.create(:work_package, project: @project, start_date: 7.days.ago, done_ratio: 60), # 14 day span, 60% done, 50% time left
        FactoryBot.create(:work_package, project: @project, start_date: 7.days.ago, done_ratio: 20) # 14 day span, 20% done, 50% time left
      ]
      assert_equal 40, @version.completed_percent
      assert_equal true, @version.behind_schedule?
    end

    it 'should be false if all of the issues are complete' do
      @version.update_attribute(:effective_date, 7.days.from_now.to_date)
      @version.work_packages = [
        FactoryBot.create(:work_package, project: @project, start_date: 14.days.ago, done_ratio: 100, status: Status.find(5)), # 7 day span
        FactoryBot.create(:work_package, project: @project, start_date: 14.days.ago, done_ratio: 100, status: Status.find(5)) # 7 day span
      ]
      assert_equal 100, @version.completed_percent
      assert_equal false, @version.behind_schedule?
    end
  end

  context '#estimated_hours' do
    before do
      (@version = Version.new.tap do |v|
        v.attributes = { project_id: 1, name: '#estimated_hours' }
      end).save!
    end

    it 'should return 0 with no assigned issues' do
      assert_equal 0, @version.estimated_hours
    end

    it 'should return 0 with no estimated hours' do
      add_work_package(@version)
      assert_equal 0, @version.estimated_hours
    end

    it 'should return the sum of estimated hours' do
      add_work_package(@version, estimated_hours: 2.5)
      add_work_package(@version, estimated_hours: 5)
      assert_equal 7.5, @version.estimated_hours
    end

    it 'should return the sum of leaves estimated hours' do
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
                          version: version,
                          subject: 'Test',
                          author: User.first,
                          type: version.project.types.first }.merge(attributes))
  end

  def assert_progress_equal(expected_float, actual_float, _message = '')
    assert_in_delta(expected_float, actual_float, 0.000001, '')
  end
end
