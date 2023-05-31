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

RSpec.describe 'baseline rendering',
               js: true,
               with_settings: { date_format: '%Y-%m-%d' } do
  shared_let(:type_bug) { create(:type_bug) }
  shared_let(:type_task) { create(:type_task) }
  shared_let(:project) { create(:project, types: [type_bug, type_task]) }
  shared_let(:user) do
    create(:user,
           firstname: 'Itsa',
           lastname: 'Me',
           member_in_project: project,
           member_with_permissions: %i[view_work_packages edit_work_packages work_package_assigned assign_versions])
  end

  shared_let(:assignee) do
    create(:user,
           firstname: 'Assigned',
           lastname: 'User',
           member_in_project: project,
           member_with_permissions: %i[view_work_packages edit_work_packages work_package_assigned])
  end

  shared_let(:default_priority) do
    create(:issue_priority, name: 'Default', is_default: true)
  end

  shared_let(:high_priority) do
    create(:issue_priority, name: 'High priority')
  end

  shared_let(:version_a) { create(:version, project:, name: 'Version A') }
  shared_let(:version_b) { create(:version, project:, name: 'Version B') }
  shared_let(:display_representation) { Components::WorkPackages::DisplayRepresentation.new }

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
      create(:work_package,
             project:,
             type: type_task,
             assigned_to: assignee,
             responsible: assignee,
             priority: default_priority,
             version: version_a,
             subject: 'Old subject',
             start_date: '2023-05-01',
             due_date: '2023-05-02')
    end

    Timecop.travel(1.day.ago) do
      WorkPackages::UpdateService
        .new(user:, model: wp)
        .call(
          subject: 'New subject',
          start_date: Date.today - 1.day,
          due_date: Date.today,
          assigned_to: user,
          responsible: user,
          priority: high_priority,
          version: version_b
        )
        .on_failure { |result| raise result.message }
        .result
    end
  end

  shared_let(:wp_task_was_bug) do
    wp = Timecop.travel(5.days.ago) do
      create(:work_package, project:, type: type_bug, subject: 'Bug changed to Task')
    end

    Timecop.travel(1.day.ago) do
      WorkPackages::UpdateService
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
      WorkPackages::UpdateService
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
    query.column_names = %w[id subject status type start_date due_date version priority assigned_to responsible]
    query.save!(validate: false)

    query
  end

  let(:wp_table) { Pages::WorkPackagesTable.new(project) }
  let(:baseline) { Components::WorkPackages::Baseline.new }

  current_user { user }

  describe 'with feature enabled', with_ee: %i[baseline_comparison], with_flag: { show_changes: true } do
    it 'does show changes' do
      wp_table.visit_query(query)
      wp_table.expect_work_package_listed wp_task, wp_task_changed, wp_task_was_bug, wp_bug_was_task
      wp_table.ensure_work_package_not_listed! wp_bug

      baseline.expect_active
      baseline.expect_added wp_task_was_bug
      baseline.expect_removed wp_bug_was_task
      baseline.expect_changed wp_task_changed
      baseline.expect_unchanged wp_task

      baseline.expect_changed_attributes wp_task_was_bug,
                                         type: %w[BUG TASK]

      baseline.expect_changed_attributes wp_bug_was_task,
                                         type: %w[TASK BUG]

      baseline.expect_changed_attributes wp_task_changed,
                                         subject: ['Old subject', 'New subject'],
                                         startDate: ['2023-05-01', (Date.today - 2.days).iso8601],
                                         dueDate: ['2023-05-02', (Date.today - 1.day).iso8601],
                                         version: ['Version A', 'Version B'],
                                         priority: ['Default', 'High priority'],
                                         assignee: ['Assigned User', 'Itsa Me'],
                                         responsible: ['Assigned User', 'Itsa Me']

      baseline.expect_unchanged_attributes wp_task_changed, :type
      baseline.expect_unchanged_attributes wp_task,
                                           :type, :subject, :start_date, :due_date,
                                           :version, :priority, :assignee, :accountable
      # show icons on work package single card
      display_representation.switch_to_card_layout
      within "wp-single-card[data-work-package-id='#{wp_bug_was_task.id}']" do
        expect(page).to have_selector(".op-table-baseline--icon-removed")
      end
      within "wp-single-card[data-work-package-id='#{wp_task_was_bug.id}']" do
        expect(page).to have_selector(".op-table-baseline--icon-added")
      end
      within "wp-single-card[data-work-package-id='#{wp_task_changed.id}']" do
        expect(page).to have_selector(".op-table-baseline--icon-changed")
      end
      within "wp-single-card[data-work-package-id='#{wp_task.id}']" do
        expect(page).not_to have_selector(".op-wp-single-card--content-baseline")
      end
    end
  end

  describe 'with feature disabled', with_flag: { show_changes: false } do
    it 'does not show changes' do
      wp_table.visit_query(query)
      wp_table.expect_work_package_listed wp_task, wp_task_changed, wp_task_was_bug
      wp_table.ensure_work_package_not_listed! wp_bug, wp_bug_was_task

      baseline.expect_inactive
    end
  end
end
