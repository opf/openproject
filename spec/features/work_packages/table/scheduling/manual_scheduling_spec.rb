require "spec_helper"

RSpec.describe "Manual scheduling", :js do
  let(:project) { create(:project, types: [type]) }
  let(:type) { create(:type) }

  let(:user) { create(:user, member_with_roles: { project => role }) }

  let!(:parent) do
    create(:work_package,
           project:,
           type:,
           subject: "Parent")
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

  before do
    login_as(user)

    wp_table.visit_query query
    wp_table.expect_work_package_listed parent, child
  end

  context "with a user allowed to edit dates" do
    let(:role) { create(:project_role, permissions: %i[view_work_packages edit_work_packages]) }

    it "allows to edit start and due date multiple times switching between scheduling modes" do
      start_date = wp_table.edit_field(parent, :startDate)
      due_date = wp_table.edit_field(parent, :dueDate)

      # Open start date
      start_date.activate!
      start_date.expect_active!

      # Expect not to be scheduled manually
      start_date.expect_scheduling_mode manually: false

      # Expect not editable
      start_date.within_modal do
        expect(page).to have_css('input[name="startDate"][disabled]')
        expect(page).to have_css('input[name="endDate"][disabled]')
        expect(page).to have_css("#{test_selector('op-datepicker-modal--action')}:not([disabled])", text: "Cancel")
        expect(page).to have_css("#{test_selector('op-datepicker-modal--action')}:not([disabled])", text: "Save")
      end

      start_date.toggle_scheduling_mode

      # Expect editable
      start_date.within_modal do
        expect(page).to have_css('input[name="startDate"]:not([disabled])')
        expect(page).to have_css('input[name="endDate"]:not([disabled])')
        expect(page).to have_css("#{test_selector('op-datepicker-modal--action')}:not([disabled])", text: "Cancel")
        expect(page).to have_css("#{test_selector('op-datepicker-modal--action')}:not([disabled])", text: "Save")
      end

      start_date.cancel_by_click

      # Both are closed
      start_date.expect_inactive!
      due_date.expect_inactive!

      # Open second date, closes first
      due_date.activate!
      due_date.expect_active!

      # Close with escape
      due_date.cancel_by_click

      start_date.activate!
      start_date.expect_scheduling_mode manually: false

      # Expect not editable
      start_date.within_modal do
        expect(page).to have_css("input[name=startDate][disabled]")
        expect(page).to have_css("input[name=endDate][disabled]")
        expect(page).to have_css("#{test_selector('op-datepicker-modal--action')}:not([disabled])", text: "Cancel")
        expect(page).to have_css("#{test_selector('op-datepicker-modal--action')}:not([disabled])", text: "Save")
      end

      start_date.toggle_scheduling_mode
      start_date.expect_calendar

      # Expect not editable
      start_date.within_modal do
        fill_in "startDate", with: "2020-07-20"
        fill_in "endDate", with: "2020-07-25"
      end

      # Wait for the debounce to be done
      sleep 1

      start_date.save!
      start_date.expect_state_text "07/20/2020"
      due_date.expect_state_text "07/25/2020"

      parent.reload
      expect(parent).to be_schedule_manually
      expect(parent.start_date.iso8601).to eq("2020-07-20")
      expect(parent.due_date.iso8601).to eq("2020-07-25")
    end
  end

  context "with a user allowed to view only" do
    let(:role) { create(:project_role, permissions: %i[view_work_packages]) }
  end
end
