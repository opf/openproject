# frozen_string_literal: true

# -- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2024 the OpenProject GmbH
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
# ++

require "spec_helper"

# This file can be safely deleted once the feature flag :percent_complete_edition
# is removed, which should happen for OpenProject 15.0 release.
# Copied from commit 109b135b
RSpec.describe "Progress modal", "pre 14.4 without percent complete edition", :js, :with_cuprite, # rubocop:disable RSpec/SortMetadata
               with_flag: { percent_complete_edition: false } do
  shared_let(:user) { create(:admin) }
  shared_let(:role) { create(:project_role) }

  shared_let(:type_task) { create(:type_task) }
  shared_let(:project) { create(:project, types: [type_task]) }
  shared_let(:priority) { create(:default_priority, name: "Normal") }
  shared_let(:open_status_with_0p_done_ratio) do
    create(:status, name: "open", default_done_ratio: 0)
  end
  shared_let(:in_progress_status_with_50p_done_ratio) do
    create(:status, name: "in progress", default_done_ratio: 50)
  end
  shared_let(:complete_status_with_100p_done_ratio) do
    create(:status, name: "complete", default_done_ratio: 100)
  end

  shared_let(:estimated_hours) { 10.0 }
  shared_let(:remaining_hours) { 5.0 }
  shared_let(:work_package) do
    create(:work_package,
           project:,
           type: type_task,
           status: open_status_with_0p_done_ratio) do |wp|
      update_work_package_with(wp, estimated_hours:, remaining_hours:)
    end
  end

  def update_work_package_with(work_package, attributes)
    WorkPackages::UpdateService.new(model: work_package,
                                    user:,
                                    contract_class: WorkPackages::CreateContract)
                               .call(**attributes)
  end

  let(:progress_query) do
    create(:query,
           project:,
           user:,
           display_sums: false,
           column_names: %i[id subject type status
                            estimated_hours remaining_hours done_ratio]) do |query|
      create(:view_work_packages_table, query:)
    end
  end

  let(:work_package_table) { Pages::WorkPackagesTable.new(project) }
  let(:work_package_row) { work_package_table.work_package_container(work_package) }
  let(:work_package_create_page) { Pages::FullWorkPackageCreate.new(project:) }

  current_user { user }

  describe "clicking on a field on the work package table" do
    it "sets the cursor after the last character on the selected input field" do
      work_package_table.visit_query(progress_query)
      work_package_table.expect_work_package_listed(work_package)

      work_edit_field = ProgressEditField.new(work_package_row, :estimatedTime)
      modal = work_edit_field.activate!

      modal.expect_cursor_at_end_of_input
    end
  end

  describe "work based mode" do
    shared_examples_for "opens the modal with its work field in focus" do
      it "opens the modal with its work field in focus" do
        work_package_table.visit_query(progress_query)
        work_package_table.expect_work_package_listed(work_package)

        work_edit_field = ProgressEditField.new(work_package_row, :estimatedTime)
        modal = work_edit_field.activate!

        modal.expect_modal_field_in_focus
      end
    end

    describe "clicking on the work field on the work package table " \
             "with no fields set" do
      before do
        update_work_package_with(work_package, estimated_hours: nil, remaining_hours: nil)
      end

      include_examples "opens the modal with its work field in focus"
    end

    describe "clicking on the work field on the work package table" \
             "with all fields set" do
      before do
        update_work_package_with(work_package, estimated_hours: 25.0, remaining_hours: 15.0)
      end

      include_examples "opens the modal with its work field in focus"
    end

    describe "clicking on the remaining work field on the work package table " \
             "with no fields set" do
      before do
        update_work_package_with(work_package, estimated_hours: nil, remaining_hours: nil)
      end

      it "opens the modal with work in focus and remaining work disabled" do
        work_package_table.visit_query(progress_query)
        work_package_table.expect_work_package_listed(work_package)

        work_edit_field = ProgressEditField.new(work_package_row, :estimatedTime)
        remaining_work_field = ProgressEditField.new(work_package_row, :remainingTime)

        remaining_work_field.activate!

        work_edit_field.expect_modal_field_in_focus
        remaining_work_field.expect_modal_field_disabled
      end
    end

    describe "clicking on the remaining work field on the work package table " \
             "with all fields set" do
      before do
        update_work_package_with(work_package, estimated_hours: 20.0, remaining_hours: 15.0)
      end

      it "opens the modal with remaining work in focus" do
        work_package_table.visit_query(progress_query)
        work_package_table.expect_work_package_listed(work_package)

        remaining_work_field = ProgressEditField.new(work_package_row, :remainingTime)

        remaining_work_field.activate!

        remaining_work_field.expect_modal_field_in_focus
      end
    end
  end

  describe "status based mode", with_settings: { work_package_done_ratio: "status" } do
    describe "clicking on the work field in the work package table " \
             "with no fields set" do
      before { update_work_package_with(work_package, estimated_hours: nil, remaining_hours: nil) }

      it "opens the modal with work in focus" do
        work_package_table.visit_query(progress_query)
        work_package_table.expect_work_package_listed(work_package)

        work_edit_field = ProgressEditField.new(work_package_row, :estimatedTime)
        modal = work_edit_field.activate!

        modal.expect_modal_field_in_focus
      end
    end

    describe "clicking on the work field in the work package table " \
             "with all fields set" do
      before { update_work_package_with(work_package, estimated_hours: 20.0, remaining_hours: 15.0) }

      it "opens the modal with work in focus" do
        work_package_table.visit_query(progress_query)
        work_package_table.expect_work_package_listed(work_package)

        work_edit_field = ProgressEditField.new(work_package_row, :estimatedTime)
        modal = work_edit_field.activate!

        modal.expect_modal_field_in_focus
      end
    end

    describe "Remaining work field" do
      it "is readonly" do
        work_package_table.visit_query(progress_query)
        work_package_table.expect_work_package_listed(work_package)

        work_field = ProgressEditField.new(work_package_row, :estimatedTime)
        remaining_work_field = ProgressEditField.new(work_package_row, :remainingTime)
        work_field.activate!

        remaining_work_field.expect_read_only_modal_field
      end
    end

    describe "Status field" do
      before { open_status_with_0p_done_ratio.update!(is_default: true) }

      it "renders only assignable statuses as options" do
        # Create a single valid transition from "open" to "in progress"
        create(:workflow,
               type_id: type_task.id,
               old_status: open_status_with_0p_done_ratio,
               new_status: in_progress_status_with_50p_done_ratio,
               role:)

        work_package_table.visit_query(progress_query)
        work_package_table.expect_work_package_listed(work_package)

        work_field = ProgressEditField.new(work_package_row, :estimatedTime)
        modal_status_field = ProgressEditField.new(work_package_row, :statusWithinProgressModal)

        work_field.activate!

        # The only defined workflow is "open" to "in progress" so "complete" must
        # not be listed as an available option
        modal_status_field.expect_select_field_with_options("open (0%)", "in progress (50%)")
        modal_status_field.expect_select_field_with_no_options("complete (100%)")

        # Create another valid transition from "open" to "complete"
        create(:workflow,
               type_id: type_task.id,
               old_status: open_status_with_0p_done_ratio,
               new_status: complete_status_with_100p_done_ratio,
               role:)

        work_package_table.visit_query(progress_query)
        work_package_table.expect_work_package_listed(work_package)

        work_field = ProgressEditField.new(work_package_row, :estimatedTime)
        modal_status_field = ProgressEditField.new(work_package_row, :statusWithinProgressModal)

        work_field.activate!
        modal_status_field.expect_select_field_with_options("open (0%)", "in progress (50%)", "complete (100%)")
      end
    end

    context "when on a new work package form" do
      specify "modal renders when no default status is set for new work packages" do
        work_package_create_page.visit!

        work_field = work_package_create_page.edit_field(:estimatedTime)
        work_field.activate!
      end

      context "with a default status set for new work packages" do
        before_all do
          open_status_with_0p_done_ratio.update!(is_default: true)

          create(:workflow,
                 type_id: type_task.id,
                 old_status: open_status_with_0p_done_ratio,
                 new_status: in_progress_status_with_50p_done_ratio,
                 role:)
          create(:workflow,
                 type_id: type_task.id,
                 old_status: open_status_with_0p_done_ratio,
                 new_status: complete_status_with_100p_done_ratio,
                 role:)
        end

        it "can create work package after setting work" do
          work_package_create_page.visit!

          work_package_create_page.set_attributes({ subject: "hello" })
          work_package_create_page.set_progress_attributes({ estimatedTime: "10h" })
          work_package_create_page.save!
          work_package_table.expect_and_dismiss_toaster(message: "Successful creation.", wait: 5)
        end

        it "renders the status selection field inside the modal as disabled " \
           "and allows setting the status solely by the top-left field" do
          work_package_create_page.visit!
          work_package_create_page.expect_fully_loaded

          work_field = work_package_create_page.edit_field(:estimatedTime)
          modal_status_field = work_package_create_page.edit_field(:statusWithinProgressModal)

          modal = work_field.activate!

          modal_status_field.expect_modal_field_disabled
          modal_status_field.expect_modal_field_value("open (0%)", disabled: true)

          modal.close!

          status_field = work_package_create_page.edit_field(:status)

          status_field.update("in progress")

          work_field.activate!
          modal_status_field.expect_modal_field_value("in progress (50%)", disabled: true)
        end

        it "can open the modal, then save without modifying anything" do
          work_package_create_page.visit!
          work_package_create_page.set_attributes({ subject: "hello" })

          work_field = work_package_create_page.edit_field(:estimatedTime)
          work_field.activate!
          work_field.submit_by_clicking_save
          work_package_create_page.expect_no_toaster(type: "error")

          work_package_create_page.save!
          work_package_table.expect_and_dismiss_toaster(message: "Successful creation.")
        end
      end
    end
  end

  describe "opening the progress modal" do
    before_all do
      create(:workflow,
             type_id: type_task.id,
             old_status: open_status_with_0p_done_ratio,
             new_status: in_progress_status_with_50p_done_ratio,
             role:)
      create(:workflow,
             type_id: type_task.id,
             old_status: open_status_with_0p_done_ratio,
             new_status: complete_status_with_100p_done_ratio,
             role:)
    end

    describe "field value format" do
      context "with all values set" do
        before { update_work_package_with(work_package, estimated_hours: 10.0, remaining_hours: 2.12345) }

        it "populates fields with correctly values formatted" do
          work_package_table.visit_query(progress_query)
          work_package_table.expect_work_package_listed(work_package)

          work_edit_field = ProgressEditField.new(work_package_row, :estimatedTime)
          remaining_work_edit_field = ProgressEditField.new(work_package_row, :remainingTime)
          percent_complete_edit_field = ProgressEditField.new(work_package_row, :percentageDone)

          work_edit_field.activate!

          work_edit_field.expect_modal_field_value("10h")
          remaining_work_edit_field.expect_modal_field_value("2.12h") # 2h 7m
          percent_complete_edit_field.expect_modal_field_value("78", readonly: true)
        end
      end

      context "with % complete set and setting long decimal values in modal" do
        before do
          work_package.attributes = {
            estimated_hours: nil, remaining_hours: nil, done_ratio: 89
          }
          work_package.save(validate: false)
        end

        it "does not lose precision due to conversion from ISO duration to hours (rounded to closest minute)" do
          work_package_table.visit_query(progress_query)
          work_package_table.expect_work_package_listed(work_package)

          work_edit_field = ProgressEditField.new(work_package_row, :estimatedTime)
          remaining_work_edit_field = ProgressEditField.new(work_package_row, :remainingTime)

          # set work to 2.5567
          work_edit_field.activate!
          work_edit_field.update("2.5567")
          work_package_table.expect_and_dismiss_toaster(message: "Successful update.")

          # work should have been set to 2.56 and remaining work to 0.28
          work_package.reload
          expect(work_package.estimated_hours).to eq(2.56)
          expect(work_package.remaining_hours).to eq(0.28)

          # work should be displayed as "2h 34m" ("2h 33m 36s" rounded to minutes),
          # and remaining work as "17m" ("16m 48s" rounded to minutes)
          work_edit_field.activate!
          work_edit_field.expect_modal_field_value("2.56h") # 2h 34m
          remaining_work_edit_field.expect_modal_field_value("0.28h") # 17m
        end
      end

      context "with unset values" do
        before { update_work_package_with(work_package, estimated_hours: nil, remaining_hours: nil) }

        it "populates fields with blank values and % Complete as '-'" do
          work_package_table.visit_query(progress_query)
          work_package_table.expect_work_package_listed(work_package)

          work_edit_field = ProgressEditField.new(work_package_row, :estimatedTime)
          remaining_work_edit_field = ProgressEditField.new(work_package_row, :remainingTime)
          percent_complete_edit_field = ProgressEditField.new(work_package_row, :percentageDone)

          work_edit_field.activate!

          work_edit_field.expect_modal_field_value("")
          remaining_work_edit_field.expect_modal_field_value("", disabled: true)
          percent_complete_edit_field.expect_modal_field_value("-", readonly: true)
        end
      end

      describe "status field", with_settings: { work_package_done_ratio: "status" } do
        it "renders the status options as the << status_name (percent_complete_value %) >>" do
          work_package_table.visit_query(progress_query)
          work_package_table.expect_work_package_listed(work_package)

          work_field = ProgressEditField.new(work_package_row, :estimatedTime)
          status_field = ProgressEditField.new(work_package_row, :statusWithinProgressModal)

          work_field.activate!

          status_field.expect_select_field_with_options("open (0%)",
                                                        "in progress (50%)",
                                                        "complete (100%)")
        end
      end
    end

    it "disables the field that triggered the modal" do
      work_package_table.visit_query(progress_query)
      work_package_table.expect_work_package_listed(work_package)

      work_edit_field = ProgressEditField.new(work_package_row, :estimatedTime)

      work_edit_field.activate!

      work_edit_field.expect_trigger_field_disabled
    end

    it "allows clicking on a field other than the one that triggered the modal " \
       "and opens the modal with said field selected" do
      work_package_table.visit_query(progress_query)
      work_package_table.expect_work_package_listed(work_package)

      work_edit_field = ProgressEditField.new(work_package_row, :estimatedTime)
      remaining_work_edit_field = ProgressEditField.new(work_package_row, :remainingTime)

      remaining_work_edit_field.activate!
      remaining_work_edit_field.expect_modal_field_in_focus
      remaining_work_edit_field.expect_trigger_field_disabled

      work_edit_field.reactivate!
      work_edit_field.expect_modal_field_in_focus
      work_edit_field.expect_trigger_field_disabled
    end
  end

  describe "% Complete field" do
    it "renders as readonly" do
      work_package_table.visit_query(progress_query)
      work_package_table.expect_work_package_listed(work_package)

      work_edit_field = ProgressEditField.new(work_package_row, :estimatedTime)
      percent_complete_edit_field = ProgressEditField.new(work_package_row, :percentageDone)

      work_edit_field.activate!

      percent_complete_edit_field.expect_read_only_modal_field
    end
  end

  describe "When % Complete is set + work and remaining work are unset coming from a migration" do
    before_all do
      work_package.reload

      work_package.estimated_hours = nil
      work_package.remaining_hours = nil
      work_package.done_ratio = 5.0
      work_package.save!(validate: false)
    end

    shared_examples_for "migration warning" do |should_render: false|
      it "renders a banner with a warning message" do
        work_package_table.visit_query(progress_query)
        work_package_table.expect_work_package_listed(work_package)

        work_edit_field = ProgressEditField.new(work_package_row, :estimatedTime)
        modal = work_edit_field.activate!

        modal.expect_migration_warning_banner(should_render:)
      end
    end

    context "on work based mode" do
      include_examples "migration warning", should_render: true
    end

    context "on status based mode", with_settings: { work_package_done_ratio: "status" } do
      include_examples "migration warning", should_render: false
    end
  end

  describe "Live-update edge cases" do
    context "given work = 10h, remaining work = 4h, % complete = 60%" do
      before { update_work_package_with(work_package, estimated_hours: 10.0, remaining_hours: 4.0) }

      specify "Case 1: When I unset work it unsets remaining work" do
        work_package_table.visit_query(progress_query)
        work_package_table.expect_work_package_listed(work_package)

        work_edit_field = ProgressEditField.new(work_package_row, :estimatedTime)
        remaining_work_edit_field = ProgressEditField.new(work_package_row, :remainingTime)

        work_edit_field.activate!
        page.driver.wait_for_network_idle # Wait for initial loading to be ready

        clear_input_field_contents(work_edit_field.input_element)
        page.driver.wait_for_network_idle # Wait for live-update to finish

        remaining_work_edit_field.expect_modal_field_value("", disabled: true)
      end

      specify "Case 2: when work is set to 12h, " \
              "remaining work is automatically set to 6h " \
              "and subsequently work is set to 14h, " \
              "remaining work updates to 1d" do
        work_package_table.visit_query(progress_query)
        work_package_table.expect_work_package_listed(work_package)

        work_edit_field = ProgressEditField.new(work_package_row, :estimatedTime)
        remaining_work_edit_field = ProgressEditField.new(work_package_row, :remainingTime)

        work_edit_field.activate!
        page.driver.wait_for_network_idle # Wait for initial loading to be ready

        work_edit_field.set_value("12")
        page.driver.wait_for_network_idle # Wait for live-update to finish
        remaining_work_edit_field.expect_modal_field_value("6h")

        work_edit_field.set_value("14")
        page.driver.wait_for_network_idle # Wait for live-update to finish
        remaining_work_edit_field.expect_modal_field_value("8h")
      end

      specify "Case 3: when work is set to 2h, " \
              "remaining work is automatically set to 0h, " \
              "and work is subsequently set to 12h, " \
              "remaining work is updated to 6h" do
        work_package_table.visit_query(progress_query)
        work_package_table.expect_work_package_listed(work_package)

        work_edit_field = ProgressEditField.new(work_package_row, :estimatedTime)
        remaining_work_edit_field = ProgressEditField.new(work_package_row, :remainingTime)

        work_edit_field.activate!
        page.driver.wait_for_network_idle # Wait for initial loading to be ready

        work_edit_field.set_value("2")
        page.driver.wait_for_network_idle # Wait for live-update to finish
        remaining_work_edit_field.expect_modal_field_value("0h")

        work_edit_field.set_value("12")
        page.driver.wait_for_network_idle # Wait for live-update to finish
        remaining_work_edit_field.expect_modal_field_value("6h")
      end
    end
  end
end
