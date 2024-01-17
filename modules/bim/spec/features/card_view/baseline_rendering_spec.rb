#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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
require_relative '../../support/pages/ifc_models/show_default'

RSpec.describe 'baseline rendering',
               :js,
               :with_cuprite,
               with_config: { edition: 'bim' },
               with_settings: { date_format: '%Y-%m-%d' } do
  shared_let(:type_bug) { create(:type_bug) }
  shared_let(:type_task) { create(:type_task) }

  shared_let(:project) do
    create(:project,
           types: [type_bug, type_task])
  end

  shared_let(:user) do
    create(:admin,
           firstname: 'Itsa',
           lastname: 'Me',
           member_with_permissions: { project => %i[view_work_packages edit_work_packages work_package_assigned
                                                    assign_versions] })
  end

  shared_let(:assignee) do
    create(:user,
           firstname: 'Assigned',
           lastname: 'User',
           member_with_permissions: { project => %i[view_work_packages edit_work_packages work_package_assigned] })
  end

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
             subject: 'Old subject',
             start_date: '2023-05-01',
             due_date: '2023-05-02')
    end

    Timecop.travel(1.day.ago) do
      WorkPackages::UpdateService
        .new(user:, model: wp)
        .call(
          subject: 'New subject',
          start_date: Time.zone.today - 1.day,
          due_date: Time.zone.today,
          assigned_to: user,
          responsible: user
        )
        .on_failure { |result| raise result.message }
        .result
    end
  end

  shared_let(:wp_task_assigned) do
    wp = Timecop.travel(5.days.ago) do
      create(:work_package,
             project:,
             type: type_task,
             assigned_to: nil)
    end

    Timecop.travel(1.day.ago) do
      WorkPackages::UpdateService
        .new(user:, model: wp)
        .call(assigned_to: user)
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
    query.column_names =
      %w[id subject status type start_date due_date version priority assigned_to responsible]
    query.save!(validate: false)

    query
  end

  let(:wp_table) { Pages::IfcModels::ShowDefault.new(project) }
  let(:baseline) { Components::WorkPackages::Baseline.new }

  current_user { user }

  describe 'with EE', with_ee: %i[baseline_comparison] do
    it 'does show changes' do
      wp_table.visit_query(query)
      wp_table.expect_work_package_listed wp_task, wp_task_changed, wp_task_was_bug, wp_bug_was_task,
                                          wp_task_assigned
      wp_table.ensure_work_package_not_listed! wp_bug

      baseline.expect_active
      baseline.expect_added wp_task_was_bug
      baseline.expect_removed wp_bug_was_task
      baseline.expect_changed wp_task_changed
      baseline.expect_changed wp_task_assigned
      baseline.expect_unchanged wp_task

      # show icons on work package single card
      wp_table.switch_view 'Cards'
      within "wp-single-card[data-work-package-id='#{wp_bug_was_task.id}']" do
        expect(page).to have_css(".op-table-baseline--icon-removed")
      end
      within "wp-single-card[data-work-package-id='#{wp_task_was_bug.id}']" do
        expect(page).to have_css(".op-table-baseline--icon-added")
      end
      within "wp-single-card[data-work-package-id='#{wp_task_changed.id}']" do
        expect(page).to have_css(".op-table-baseline--icon-changed")
      end
      within "wp-single-card[data-work-package-id='#{wp_task.id}']" do
        expect(page).to have_no_css(".op-wp-single-card--content-baseline")
      end
    end
  end
end
