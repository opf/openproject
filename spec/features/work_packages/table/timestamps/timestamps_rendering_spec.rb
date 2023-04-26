#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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

require 'spec_helper'

describe 'timestamps rendering', js: true do
  shared_let(:type_bug) { create(:type_bug) }
  shared_let(:type_task) { create(:type_task) }
  shared_let(:project) { create(:project, types: [type_bug, type_task]) }
  shared_let(:user) do
    create(:user,
           member_in_project: project,
           member_with_permissions: %i[view_work_packages edit_work_packages])
  end

  shared_let(:wp_bug) do
    create(:work_package,
           project:,
           type: type_bug,
           subject: 'A bug',
           created_at: 5.days.ago,
           updated_at: 5.days.ago)
  end

  shared_let(:wp_task) do
    create(:work_package,
           project:,
           type: type_task,
           subject: 'A task',
           created_at: 5.days.ago,
           updated_at: 5.days.ago)
  end

  shared_let(:wp_task_changed) do
    wp = Timecop.travel(5.days.ago) do
      create(:work_package, project:, type: type_task, subject: 'Old subject')
    end

    Timecop.travel(1.day.ago) do
      ::WorkPackages::UpdateService
        .new(user:, model: wp)
        .call(subject: 'New subject')
        .on_failure { |result| raise result.message }
        .result
    end
  end

  shared_let(:wp_task_was_bug) do
    wp = Timecop.travel(5.days.ago) do
      create(:work_package, project:, type: type_bug, subject: 'Bug changed to Task')
    end

    Timecop.travel(1.day.ago) do
      ::WorkPackages::UpdateService
        .new(user:, model: wp)
        .call(type: type_task)
        .on_failure { |result| raise result.message }
        .result
    end
  end

  shared_let(:wp_bug_was_task) do
    wp = Timecop.travel(5.days.ago) do
      create(:work_package, project:, type: type_task, subject: 'Task changed to Bug')
    end

    Timecop.travel(1.day.ago) do
      ::WorkPackages::UpdateService
        .new(user:, model: wp)
        .call(type: type_bug)
        .on_failure { |result| raise result.message }
        .result
    end
  end

  shared_let(:query) do
    query = create(:query,
                   name: 'Timestamps Query',
                   project:,
                   user:)

    query.timestamps = ["P-2d", "PT0S"]
    query.add_filter('type_id', '=', [type_task.id])
    query.save!(validate: false)

    query
  end

  let(:wp_table) { Pages::WorkPackagesTable.new(project) }
  let(:timestamps) { Components::WorkPackages::Timestamps.new }

  current_user { user }

  describe 'with feature enabled', with_flag: { show_changes: true } do
    it 'does show changes' do
      wp_table.visit_query(query)
      wp_table.expect_work_package_listed wp_task, wp_task_changed, wp_task_was_bug, wp_bug_was_task
      wp_table.ensure_work_package_not_listed! wp_bug

      timestamps.expect_active
      timestamps.expect_added wp_task_was_bug
      timestamps.expect_removed wp_bug_was_task
      timestamps.expect_changed wp_task_changed
      timestamps.expect_unchanged wp_task
    end
  end

  describe 'with feature disabled', with_flag: { show_changes: false } do
    it 'does not show changes' do
      wp_table.visit_query(query)
      wp_table.expect_work_package_listed wp_task, wp_task_changed, wp_task_was_bug
      wp_table.ensure_work_package_not_listed! wp_bug, wp_bug_was_task

      timestamps.expect_inactive
    end
  end
end
