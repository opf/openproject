require "spec_helper"

RSpec.describe "Duration field in the work package table", :js do
  shared_let(:current_user) { create(:admin) }
  shared_let(:work_package) do
    next_monday = Time.zone.today.beginning_of_week.next_occurring(:monday)
    create(:work_package,
           subject: "moved",
           author: current_user,
           start_date: next_monday,
           due_date: next_monday.next_occurring(:thursday))
  end

  let!(:wp_table) { Pages::WorkPackagesTable.new(work_package.project) }
  let!(:query) do
    query              = build(:query, user: current_user, project: work_package.project)
    query.column_names = %w(subject start_date due_date duration)
    query.filters.clear
    query.show_hierarchies = false

    query.save!
    query
  end

  let(:duration) { wp_table.edit_field work_package, :duration }
  let(:date_field) { wp_table.edit_field work_package, :startDate }

  before do
    login_as(current_user)

    wp_table.visit_query query
    wp_table.expect_work_package_listed work_package
  end

  it "shows the duration as days and opens the datepicker on click" do
    duration.expect_state_text "4 days"
    duration.activate!

    date_field.expect_duration_highlighted
    expect(page).to have_focus_on("#{test_selector('op-datepicker-modal--duration-field')} input[name='duration']")
    expect(page).to have_field("duration", with: "4", wait: 10)
  end
end
