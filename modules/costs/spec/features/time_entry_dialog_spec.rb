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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require_relative "../spec_helper"

RSpec.describe "time entry dialog", :js do
  include Redmine::I18n

  shared_let(:project) { create(:project_with_types) }

  shared_let(:work_package_a) { create(:work_package, subject: "WP A", project:) }
  shared_let(:work_package_b) { create(:work_package, subject: "WP B", project:) }

  let(:time_logging_modal) { Components::TimeLoggingModal.new }

  let(:user) { create(:user, member_with_permissions: { project => permissions }) }

  before do
    login_as user
  end

  context "when user has permission to log own time" do
    let(:permissions) { %i[log_own_time view_own_time_entries view_work_packages] }

    before do
      visit work_package_path(work_package_a)

      find("#action-show-more-dropdown-menu .button").click
      find(".menu-item", text: "Log time").click
    end

    it "does not show the user autocompleter" do
      time_logging_modal.is_visible(true)
      time_logging_modal.shows_field("user_id", false)
    end

    context "when start and end time is not allowed", with_settings: { allow_tracking_start_and_end_times: false } do
      it "does not show fields to track start and end times" do
        time_logging_modal.shows_field("start_time", false)
        time_logging_modal.shows_field("end_time", false)
        time_logging_modal.shows_field("hours_display", true)
      end
    end

    context "when start and end time is allowed", with_settings: { allow_tracking_start_and_end_times: true } do
      it "shows fields to track start and end times" do
        time_logging_modal.shows_field("start_time", true)
        time_logging_modal.requires_field("start_time", required: false)
        time_logging_modal.shows_field("end_time", true)
        time_logging_modal.requires_field("end_time", required: false)
        time_logging_modal.shows_field("hours_display", true)
      end
    end

    context "when start and end time is enforced",
            with_ee: %i[time_entry_time_restrictions],
            with_settings: {
              allow_tracking_start_and_end_times: true,
              enforce_tracking_start_and_end_times: true
            } do
      it "shows fields to track start and end times" do
        time_logging_modal.shows_field("start_time", true)
        time_logging_modal.requires_field("start_time")
        time_logging_modal.shows_field("end_time", true)
        time_logging_modal.requires_field("end_time")
        time_logging_modal.shows_field("hours_display", true)
      end
    end
  end

  context "when user has permission to log time for others" do
    let!(:other_user) do
      create(
        :user,
        firstname: "Max",
        lastname: "Mustermann",
        preferences: {
          time_zone: "Asia/Tokyo"
        },
        member_with_permissions: { project => [:view_project] }
      )
    end
    let(:permissions) { %i[log_time view_time_entries view_work_packages] }

    before do
      visit work_package_path(work_package_a)

      find("#action-show-more-dropdown-menu .button").click
      find(".menu-item", text: "Log time").click
    end

    it "shows the user autocompleter and prefills it with the current user" do
      time_logging_modal.is_visible(true)
      time_logging_modal.shows_field("user_id", true)
      time_logging_modal.expect_user(user)

      time_logging_modal.update_field("user_id", other_user.name)

      time_logging_modal.expect_user(other_user)
      time_logging_modal.shows_caption(I18n.t("notice_different_time_zones", tz: friendly_timezone_name(other_user.time_zone)))
    end
  end

  describe "calculating logic", with_settings: { allow_tracking_start_and_end_times: true } do
    let(:permissions) { %i[log_own_time view_own_time_entries view_work_packages] }

    before do
      visit work_package_path(work_package_a)

      find("#action-show-more-dropdown-menu .button").click
      find(".menu-item", text: "Log time").click
    end

    it "normalizes the hour input" do
      time_logging_modal.update_field("hours_display", "6h 45min")
      time_logging_modal.has_field_with_value("hours_display", "6.75h")

      time_logging_modal.update_field("hours_display", "4:15")
      time_logging_modal.has_field_with_value("hours_display", "4.25h")

      time_logging_modal.update_field("hours_display", "1m 2w 3d 4h 5m")
      time_logging_modal.has_field_with_value("hours_display", "412.1h")

      time_logging_modal.update_field("hours_display", "1.5")
      time_logging_modal.has_field_with_value("hours_display", "1.5h")

      time_logging_modal.update_field("hours_display", "3,7")
      time_logging_modal.has_field_with_value("hours_display", "3.7h")
    end

    it "calculates the hours based on the start and end time" do
      time_logging_modal.update_time_field("start_time", hour: 10, minute: 0)
      time_logging_modal.update_time_field("end_time", hour: 12, minute: 30)

      time_logging_modal.has_field_with_value("hours_display", "2.5h")
    end

    it "correctly handles when end_time < start_time (multiple days)" do
      time_logging_modal.update_time_field("start_time", hour: 10, minute: 0)
      time_logging_modal.update_time_field("end_time", hour: 9, minute: 45)

      time_logging_modal.has_field_with_value("hours_display", "23.75h")
      time_logging_modal.shows_caption("+1 day")
    end

    it "correctly handles when hours > 24" do
      time_logging_modal.update_time_field("start_time", hour: 10, minute: 0)
      time_logging_modal.update_field("hours_display", "50h")

      time_logging_modal.has_field_with_value("end_time", "12:00")
      time_logging_modal.shows_caption("+2 days")
    end

    it "calculates the end time based on start time and hours" do
      time_logging_modal.update_time_field("start_time", hour: 10, minute: 0)
      time_logging_modal.update_field("hours_display", "3h")

      time_logging_modal.has_field_with_value("end_time", "13:00")
    end

    it "calculates the start time based on end time and hours" do
      time_logging_modal.update_time_field("end_time", hour: 10, minute: 0)
      time_logging_modal.update_field("hours_display", "3h")

      time_logging_modal.has_field_with_value("start_time", "07:00")
    end

    it "recalculates the end time, when changing the hours field" do
      time_logging_modal.update_time_field("start_time", hour: 10, minute: 0)
      time_logging_modal.update_time_field("end_time", hour: 12, minute: 30)

      time_logging_modal.has_field_with_value("hours_display", "2.5h")

      time_logging_modal.update_field("hours_display", "6h")

      time_logging_modal.has_field_with_value("end_time", "16:00")
    end

    it "recalculates the end time, when changing the start_time field" do
      time_logging_modal.update_time_field("start_time", hour: 10, minute: 0)
      time_logging_modal.update_time_field("end_time", hour: 12, minute: 30)

      time_logging_modal.has_field_with_value("hours_display", "2.5h")

      time_logging_modal.update_time_field("start_time", hour: 12, minute: 0)

      time_logging_modal.has_field_with_value("end_time", "14:30")
      time_logging_modal.has_field_with_value("hours_display", "2.5h")
    end
  end

  describe "custom field validation" do
    let(:permissions) { %i[log_own_time view_own_time_entries view_work_packages] }
    let!(:required_custom_field) do
      create(:time_entry_custom_field, :string,
             name: "Department",
             is_required: true)
    end

    before do
      visit work_package_path(work_package_a)

      find("#action-show-more-dropdown-menu .button").click
      find(".menu-item", text: "Log time").click
      time_logging_modal.is_visible(true)
      time_logging_modal.update_field("hours_display", "2")
    end

    it "I can create a time entry with a custom field value including validation" do
      # validates the required custom field and prevents creation when missing
      expect do
        time_logging_modal.submit
        wait_for_network_idle
      end.not_to change(TimeEntry, :count)

      time_logging_modal.field_has_error("custom_field_values_#{required_custom_field.id}", "Value can't be blank.")

      # creates the time entry when the required custom field is provided
      time_logging_modal.update_field("custom_field_values_#{required_custom_field.id}", "Engineering")

      expect do
        time_logging_modal.submit
        wait_for_network_idle
      end.to change(TimeEntry, :count).by(1)

      # Verify the time entry was created with the custom field value
      time_entry = TimeEntry.last
      expect(time_entry.typed_custom_value_for(required_custom_field)).to eq("Engineering")
      expect(time_entry.entity).to eq(work_package_a)
    end
  end

  describe "when the user can edit time entries" do
    let(:permissions) { %i[log_own_time view_own_time_entries edit_own_time_entries view_work_packages] }
    let!(:time_entry) { create(:time_entry, entity: work_package_a, project: work_package_a.project, user: user) }

    context "with work packages from different projects" do
      let(:other_project) { create(:project_with_types) }
      let(:work_package_c) { create(:work_package, subject: "WP C", project: other_project) }

      let(:user) { create(:user, member_with_permissions: { project => permissions, other_project => permissions }) }

      it "allows switching to a work package of a different project (Regression #62066)" do
        visit cost_reports_path(work_package_a.project_id,
                                { fields: ["WorkPackageId"],
                                  operators: { WorkPackageId: "=" },
                                  values: { WorkPackageId: [work_package_a.id, work_package_b.id, work_package_c.id] },
                                  set_filter: 1 })

        # make sure that the work package is shown in the table
        expect(page).to have_css("#result-table td[raw-data='#{work_package_a.id}']", text: work_package_a.subject)

        find("opce-time-entry-trigger-actions .icon-edit").click

        time_logging_modal.is_visible(true)
        time_logging_modal.update_field("entity_id", work_package_c.subject)
        wait_for_network_idle # form refresh is happening here
        time_logging_modal.submit
        wait_for_network_idle

        expect(page).to have_css("#result-table td[raw-data='#{work_package_c.id}']", text: work_package_c.subject)

        # also check that everything is updated in the database
        time_entry.reload
        expect(time_entry.entity).to eq(work_package_c)
      end
    end

    it "updates the time entry instead of creating a new one (Regression #61657)" do
      visit cost_reports_path(work_package_a.project_id,
                              { fields: ["WorkPackageId"],
                                operators: { WorkPackageId: "=" },
                                values: { WorkPackageId: [work_package_a.id, work_package_b.id] },
                                set_filter: 1 })

      # make sure that the work package is shown in the table
      expect(page).to have_css("#result-table td[raw-data='#{work_package_a.id}']", text: work_package_a.subject)

      find("opce-time-entry-trigger-actions .icon-edit").click

      expect do
        time_logging_modal.is_visible(true)
        time_logging_modal.update_field("entity_id", work_package_b.subject)
        wait_for_network_idle # form refresh is happening here
        time_logging_modal.submit
        wait_for_network_idle
      end.not_to change(TimeEntry, :count)

      expect(page).to have_css("#result-table td[raw-data='#{work_package_b.id}']", text: work_package_b.subject)

      # also check that everything is updated in the database
      time_entry.reload
      expect(time_entry.entity).to eq(work_package_b)
    end

    context "with custom field validation" do
      let!(:required_custom_field) do
        create(:time_entry_custom_field, :string,
               name: "Department",
               is_required: true)
      end

      it "I can update a time entry with a custom field value including validation" do
        visit cost_reports_path(work_package_a.project_id,
                                { fields: ["WorkPackageId"],
                                  operators: { WorkPackageId: "=" },
                                  values: { WorkPackageId: [work_package_a.id] },
                                  set_filter: 1 })

        # make sure that the work package is shown in the table
        expect(page).to have_css("#result-table td[raw-data='#{work_package_a.id}']", text: work_package_a.subject)
        find("opce-time-entry-trigger-actions .icon-edit").click

        time_logging_modal.is_visible(true)

        # ensure the work package autocompleter is filled
        time_logging_modal.update_field("entity_id", work_package_a.subject)

        # validates the required custom field and prevents update when missing
        time_logging_modal.submit
        wait_for_network_idle

        time_logging_modal.field_has_error("custom_field_values_#{required_custom_field.id}", "Value can't be blank.")

        # updates the time entry when the required custom field is provided
        time_logging_modal.update_field("custom_field_values_#{required_custom_field.id}", "Marketing & Sales")

        time_logging_modal.submit
        wait_for_network_idle

        # Verify the custom field value was updated
        time_entry.reload
        expect(time_entry.typed_custom_value_for(required_custom_field)).to eq("Marketing & Sales")
      end
    end
  end
end
