# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe "Manual scheduling", :js do
  let(:project) { create(:project, types: [type]) }
  let(:type) { create(:type) }

  let(:user) { create(:user, member_with_roles: { project => role }) }

  let!(:parent) do
    create(:work_package,
           project:,
           type:,
           subject: "Parent",
           schedule_manually: false)
  end

  let!(:child) do
    create(:work_package,
           project:,
           parent:,
           type:,
           subject: "Child")
  end

  let!(:wp_table) { Pages::WorkPackagesTable.new(project) }
  let!(:query) do
    query = build(:query, user:, project:)
    query.column_names = %w(subject start_date due_date)
    query.filters.clear
    query.show_hierarchies = false

    query.save!
    query
  end
  let(:start_date_field) { wp_table.edit_field(parent, :startDate) }
  let(:due_date_field) { wp_table.edit_field(parent, :dueDate) }
  let(:datepicker) { start_date_field.datepicker }

  before do
    login_as(user)

    wp_table.visit_query query
    wp_table.expect_work_package_listed parent, child
  end

  context "with a user allowed to edit dates" do
    let(:role) { create(:project_role, permissions: %i[view_work_packages edit_work_packages]) }

    it "allows to edit start and due date multiple times switching between scheduling modes" do
      # Open start date
      start_date_field.activate!
      datepicker.expect_visible

      # Expect automatic scheduling
      datepicker.expect_automatic_scheduling_mode

      # Expect not editable
      datepicker.expect_start_date "", disabled: true
      datepicker.expect_due_date "", disabled: true
      datepicker.expect_cancel_button_enabled
      datepicker.expect_save_button_enabled

      # Toggle to manual scheduling mode
      datepicker.toggle_scheduling_mode

      # Expect editable in single mode with start date field visible
      datepicker.expect_add_finish_date_button_visible
      datepicker.expect_start_date ""
      datepicker.expect_cancel_button_enabled
      datepicker.expect_save_button_enabled

      # Close date picker by clicking on the Cancel button
      datepicker.cancel!

      # Both are closed
      start_date_field.expect_inactive!
      due_date_field.expect_inactive!

      # Open second date, closes first
      due_date_field.activate!
      datepicker.expect_visible

      # Close date picker by clicking on the Cancel button
      datepicker.cancel!

      # Open datepicker again
      start_date_field.activate!
      datepicker.expect_automatic_scheduling_mode

      # Expect not editable
      datepicker.expect_start_date "", disabled: true
      datepicker.expect_due_date "", disabled: true
      datepicker.expect_cancel_button_enabled
      datepicker.expect_save_button_enabled

      # Toggle to manual scheduling mode
      datepicker.toggle_scheduling_mode

      # Enable start date then set dates
      datepicker.expect_add_finish_date_button_visible
      datepicker.enable_due_date
      datepicker.set_start_date "2020-07-20"
      datepicker.set_due_date "2020-07-25"
      datepicker.save!

      start_date_field.expect_state_text "07/20/2020"
      due_date_field.expect_state_text "07/25/2020"

      parent.reload
      expect(parent).to be_schedule_manually
      expect(parent.start_date.iso8601).to eq("2020-07-20")
      expect(parent.due_date.iso8601).to eq("2020-07-25")
    end
  end
end
