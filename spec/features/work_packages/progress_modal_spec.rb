# frozen_string_literal: true

# -- copyright
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
# ++

require "spec_helper"

RSpec.describe "Progress modal", :js, :with_cuprite,
               with_flag: { percent_complete_edition: true } do
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
  let(:progress_popover) { work_package_table.progress_popover(work_package) }
  let(:work_package_create_page) { Pages::FullWorkPackageCreate.new(project:) }

  current_user { user }

  def visit_progress_query_displaying_work_package
    work_package_table.visit_query(progress_query)
    work_package_table.expect_work_package_listed(work_package)
  end

  describe "clicking on a field on the work package table" do
    it "sets the cursor after the last character on the selected input field" do
      visit_progress_query_displaying_work_package

      progress_popover.open_by_clicking_on_field(:work)
      progress_popover.expect_cursor_at_end_of_input(:work)
    end
  end

  describe "work based mode" do
    shared_examples_for "opens the modal with the clicked field in focus" do
      it "when clicking on a field opens the modal and focuses on the related modal input field", :aggregate_failures do
        visit_progress_query_displaying_work_package

        %i[work remaining_work percent_complete].each do |field_name|
          progress_popover.open_by_clicking_on_field(field_name)
          progress_popover.expect_focused(field_name)
          progress_popover.close
        end
      end
    end

    context "with no fields set" do
      before do
        update_work_package_with(work_package, estimated_hours: nil, remaining_hours: nil, done_ratio: nil)
      end

      include_examples "opens the modal with the clicked field in focus"
    end

    context "with all fields set" do
      before do
        update_work_package_with(work_package, estimated_hours: 25.0, remaining_hours: 15.0)
      end

      include_examples "opens the modal with the clicked field in focus"
    end
  end

  describe "status based mode", with_settings: { work_package_done_ratio: "status" } do
    describe "clicking on the work field in the work package table " \
             "with no fields set" do
      before { update_work_package_with(work_package, estimated_hours: nil, remaining_hours: nil) }

      it "opens the modal with work in focus" do
        visit_progress_query_displaying_work_package

        progress_popover.open_by_clicking_on_field(:work)
        progress_popover.expect_focused(:work)
      end
    end

    describe "clicking on the work field in the work package table " \
             "with all fields set" do
      before { update_work_package_with(work_package, estimated_hours: 20.0, remaining_hours: 15.0) }

      it "opens the modal with work in focus" do
        visit_progress_query_displaying_work_package

        progress_popover.open_by_clicking_on_field(:work)
        progress_popover.expect_focused(:work)
      end
    end

    describe "Remaining work field" do
      it "is readonly" do
        visit_progress_query_displaying_work_package

        progress_popover.open
        progress_popover.expect_read_only(:remaining_work)
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

        visit_progress_query_displaying_work_package
        progress_popover.open

        # The only defined workflow is "open" to "in progress" so "complete" must
        # not be listed as an available option
        progress_popover.expect_select_with_options(:status, "open (0%)", "in progress (50%)")
        progress_popover.expect_select_without_options(:status, "complete (100%)")

        # Create another valid transition from "open" to "complete"
        create(:workflow,
               type_id: type_task.id,
               old_status: open_status_with_0p_done_ratio,
               new_status: complete_status_with_100p_done_ratio,
               role:)

        visit_progress_query_displaying_work_package
        progress_popover.open

        progress_popover.expect_select_with_options(:status, "open (0%)", "in progress (50%)", "complete (100%)")
      end
    end

    context "when on a new work package form" do
      let(:progress_popover) { Components::WorkPackages::ProgressPopover.new(create_form: true) }

      specify "modal renders when no default status is set for new work packages" do
        work_package_create_page.visit!

        progress_popover.open
        progress_popover.expect_value(:status, :empty_without_any_options, disabled: true)
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

          expect(WorkPackage.order(id: :asc).last).to have_attributes(
            estimated_hours: 10.0,
            remaining_hours: 10.0,
            done_ratio: 0
          )
        end

        it "renders the status selection field inside the modal as disabled " \
           "and allows setting the status solely by the top-left field" do
          work_package_create_page.visit!
          work_package_create_page.expect_fully_loaded

          progress_popover.open
          progress_popover.expect_disabled(:status)
          progress_popover.expect_value(:status, "open (0%)", disabled: true)

          progress_popover.close

          status_field = work_package_create_page.edit_field(:status)
          status_field.update("in progress")

          progress_popover.open
          progress_popover.expect_value(:status, "in progress (50%)", disabled: true)
        end

        it "can open the modal, then save without modifying anything" do
          work_package_create_page.visit!
          work_package_create_page.set_attributes({ subject: "hello" })

          progress_popover.open
          progress_popover.save
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

        it "populates fields with values correctly formatted" do
          visit_progress_query_displaying_work_package

          progress_popover.open
          progress_popover.expect_values(
            work: "10h",
            remaining_work: "2.12h", # 2h 7m
            percent_complete: "79%"
          )
        end
      end

      context "on create page" do
        it "can create work package after setting progress values multiple times" do
          work_package_create_page.visit!

          work_package_create_page.set_attributes({ subject: "hello" })
          work_edit_field = ProgressEditField.new("#content", :estimatedTime)
          remaining_work_edit_field = ProgressEditField.new("#content", :remainingTime)
          percent_complete_edit_field = ProgressEditField.new("#content", :percentageDone)
          expect(work_edit_field.trigger_element.value).to eq("-")
          expect(remaining_work_edit_field.trigger_element.value).to eq("-")
          expect(percent_complete_edit_field.trigger_element.value).to eq("-")

          work_package_create_page.set_progress_attributes({ estimatedTime: "0h" })
          expect(work_edit_field.trigger_element.value).to eq("0h")
          expect(remaining_work_edit_field.trigger_element.value).to eq("0h")
          expect(percent_complete_edit_field.trigger_element.value).to eq("-")

          work_package_create_page.set_progress_attributes({ estimatedTime: "5h" })
          expect(work_edit_field.trigger_element.value).to eq("5h")
          expect(remaining_work_edit_field.trigger_element.value).to eq("5h")
          expect(percent_complete_edit_field.trigger_element.value).to eq("0%")

          work_package_create_page.set_progress_attributes({ percentageDone: "40%" })
          expect(work_edit_field.trigger_element.value).to eq("5h")
          expect(remaining_work_edit_field.trigger_element.value).to eq("3h")
          expect(percent_complete_edit_field.trigger_element.value).to eq("40%")

          work_package_create_page.save!
          work_package_table.expect_and_dismiss_toaster(message: "Successful creation.", wait: 5)

          expect(WorkPackage.order(id: :asc).last).to have_attributes(
            estimated_hours: 5.0,
            remaining_hours: 3.0,
            done_ratio: 40
          )
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
          visit_progress_query_displaying_work_package

          # set work to 2.5567
          progress_popover.open
          progress_popover.set_values(work: "2.5567")
          progress_popover.save
          work_package_table.expect_and_dismiss_toaster(message: "Successful update.")

          # work should have been set to 2.56 and remaining work to 0.28
          work_package.reload
          expect(work_package.estimated_hours).to eq(2.56)
          expect(work_package.remaining_hours).to eq(0.28)

          # work should be displayed as "2h 34m" ("2h 33m 36s" rounded to minutes),
          # and remaining work as "17m" ("16m 48s" rounded to minutes)
          progress_popover.open
          progress_popover.expect_values(
            work: "2.56h", # 2h 34m
            remaining_work: "0.28h" # 17m
          )
        end
      end

      context "with empty values" do
        before do
          update_work_package_with(work_package, estimated_hours: nil, remaining_hours: nil, done_ratio: nil)
        end

        it "populates all fields with blank values" do
          visit_progress_query_displaying_work_package

          progress_popover.open
          progress_popover.expect_values(
            work: "",
            remaining_work: "",
            percent_complete: ""
          )
        end
      end

      describe "status field", with_settings: { work_package_done_ratio: "status" } do
        it "renders the status options as the << status_name (percent_complete_value %) >>" do
          visit_progress_query_displaying_work_package

          progress_popover.open
          progress_popover.expect_select_with_options(:status,
                                                      "open (0%)",
                                                      "in progress (50%)",
                                                      "complete (100%)")
        end
      end
    end

    it "disables the field that triggered the modal" do
      visit_progress_query_displaying_work_package

      work_edit_field = ProgressEditField.new(work_package_row, :estimatedTime)

      work_edit_field.activate!

      work_edit_field.expect_trigger_field_disabled
    end

    it "allows clicking on a field other than the one that triggered the modal " \
       "and opens the modal with said field selected" do
      visit_progress_query_displaying_work_package

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

  describe "Live-update edge cases" do
    context "given work = 10h, remaining work = 4h, % complete = 60%" do
      before { update_work_package_with(work_package, estimated_hours: 10.0, remaining_hours: 4.0) }

      specify "Case 1: When I clear work it clears remaining work" do
        visit_progress_query_displaying_work_package

        progress_popover.open
        progress_popover.set_values(work: "")
        progress_popover.expect_values(remaining_work: "")
      end

      specify "Case 2: when work is set to 12h, " \
              "remaining work is automatically set to 6h " \
              "and subsequently work is set to 14h, " \
              "remaining work updates to 8h" do
        visit_progress_query_displaying_work_package

        progress_popover.open
        progress_popover.set_values(work: "12")
        progress_popover.expect_values(remaining_work: "6h")

        progress_popover.set_values(work: "14")
        progress_popover.expect_values(remaining_work: "8h")
      end

      specify "Case 3: when work is set to 2h, " \
              "remaining work is automatically set to 0h, " \
              "and work is subsequently set to 12h, " \
              "remaining work is updated to 6h" do
        visit_progress_query_displaying_work_package

        progress_popover.open
        progress_popover.set_values(work: "2")
        progress_popover.expect_values(remaining_work: "0h")

        progress_popover.set_values(work: "12")
        progress_popover.expect_values(remaining_work: "6h")
      end

      specify "Case 23-7: when remaining work or % complete are set, work never " \
              "changes, instead remaining work and % complete are derived" do
        visit_progress_query_displaying_work_package

        progress_popover.open
        progress_popover.set_values(remaining_work: "2h")
        progress_popover.expect_values(work: "10h", percent_complete: "80%")

        progress_popover.set_values(percent_complete: "50%")
        progress_popover.expect_values(work: "10h", remaining_work: "5h")

        progress_popover.set_values(remaining_work: "9h")
        progress_popover.expect_values(work: "10h", percent_complete: "10%")
      end

      # scenario from https://community.openproject.org/wp/57370
      specify "Case 23-11: when work is cleared, and remaining work is set, " \
              "then work is derived again" do
        visit_progress_query_displaying_work_package

        progress_popover.open
        # clear work
        progress_popover.set_values(work: "")
        progress_popover.expect_values(work: "", remaining_work: "", percent_complete: "60%")

        # set remaining work
        progress_popover.set_values(remaining_work: "8h")
        # work is derived
        progress_popover.expect_values(work: "20h", remaining_work: "8h", percent_complete: "60%")
      end

      # scenario from https://community.openproject.org/wp/57370
      specify "Case 23-14: when remaining work is cleared, and work is set, " \
              "then remaining work is derived again" do
        visit_progress_query_displaying_work_package

        progress_popover.open
        # clear work
        progress_popover.set_values(remaining_work: "")
        progress_popover.expect_values(work: "", remaining_work: "", percent_complete: "60%")

        # set remaining work
        progress_popover.set_values(work: "20h")
        # => work is derived
        progress_popover.expect_values(work: "20h", remaining_work: "8h", percent_complete: "60%")
      end

      # scenario from https://community.openproject.org/wp/57370
      specify "Case 33-1: when work and % complete are cleared, and then work " \
              "is set again then % complete is derived again" do
        visit_progress_query_displaying_work_package

        progress_popover.open
        # clear work and % complete
        progress_popover.set_values(work: "", percent_complete: "")
        progress_popover.expect_values(work: "", remaining_work: "4h", percent_complete: "")

        # set work
        progress_popover.set_values(work: "20h")
        # => % complete is derived
        progress_popover.expect_values(work: "20h", remaining_work: "4h", percent_complete: "80%")
      end

      # scenario from https://community.openproject.org/wp/57370
      specify "Case 33-2: when remaining work and % complete are cleared, " \
              "changing or clearing work does not modify % complete at all" do
        visit_progress_query_displaying_work_package

        progress_popover.open
        progress_popover.set_values(remaining_work: "")
        progress_popover.expect_values(work: "", remaining_work: "", percent_complete: "60%")
        progress_popover.expect_hints(work: :cleared_because_remaining_work_is_empty)

        progress_popover.set_values(percent_complete: "")
        progress_popover.expect_values(work: "10h", remaining_work: "", percent_complete: "")
        progress_popover.expect_hints(work: nil, remaining_work: nil, percent_complete: nil)

        # partially deleting work value like when pressing backspace
        progress_popover.set_values(work: "1")
        progress_popover.expect_values(work: "1", remaining_work: "", percent_complete: "")
        progress_popover.expect_hints(work: nil, remaining_work: nil, percent_complete: nil)

        # completly clearing work value
        progress_popover.set_values(work: "")
        progress_popover.expect_values(work: "", remaining_work: "", percent_complete: "")
        progress_popover.expect_hints(work: nil, remaining_work: nil, percent_complete: nil)
      end
    end

    context "given work, remaining work, and % complete are all empty" do
      before do
        update_work_package_with(work_package, estimated_hours: nil, remaining_hours: nil, done_ratio: nil)
      end

      # scenario from https://community.openproject.org/wp/57370
      specify "Case 20-4: when remaining work and % complete are both set, work " \
              "is derived because it's initially empty" do
        visit_progress_query_displaying_work_package

        progress_popover.open
        progress_popover.set_values(remaining_work: "2h", percent_complete: "50%")
        progress_popover.expect_values(work: "4h")

        progress_popover.set_values(remaining_work: "10h")
        progress_popover.expect_values(work: "20h")
      end

      # scenario from https://community.openproject.org/wp/57370
      specify "Case 30-1: when % complete is set, remaining work is set, and " \
              "% complete is changed, then work is always derived" do
        visit_progress_query_displaying_work_package

        progress_popover.open
        progress_popover.set_values(percent_complete: "40%")
        progress_popover.expect_values(work: "", remaining_work: "", percent_complete: "40%")

        progress_popover.set_values(remaining_work: "60h")
        progress_popover.expect_values(work: "100h", remaining_work: "60h", percent_complete: "40%")

        progress_popover.set_values(percent_complete: "80%")
        progress_popover.expect_values(work: "300h", remaining_work: "60h", percent_complete: "80%")
      end
    end
  end
end
