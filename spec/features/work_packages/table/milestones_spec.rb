require "spec_helper"

RSpec.describe "Inline editing milestones", :js do
  let(:user) { create(:admin) }

  let(:type) { create(:type, is_milestone: true) }
  let(:project) { create(:project, types: [type]) }
  let!(:work_package) do
    create(:work_package,
           project:,
           type:,
           subject: "Foobar")
  end

  let!(:wp_table) { Pages::WorkPackagesTable.new(project) }
  let!(:query) do
    query              = build(:query, user:, project:)
    query.column_names = %w(subject start_date due_date)
    query.filters.clear
    query.show_hierarchies = false

    query.save!
    query
  end

  before do
    login_as(user)

    wp_table.visit_query query
    wp_table.expect_work_package_listed work_package
  end

  it "mapping for start and finish date in the table (regression #26044)" do
    start_date = wp_table.edit_field(work_package, :startDate)
    due_date = wp_table.edit_field(work_package, :dueDate)

    # Open start date
    start_date.activate!
    start_date.expect_active!

    # Open second date, closes first
    scroll_to_and_click(due_date.display_element)
    due_date.expect_active!

    # Close with escape
    due_date.cancel_by_escape

    start_date.expect_inactive!
    due_date.expect_inactive!

    start_date.update "2017-08-07"
    start_date.expect_inactive!
    start_date.expect_state_text "08/07/2017"
    due_date.expect_state_text "08/07/2017"

    work_package.reload
    expect work_package.milestone?
    expect(work_package.start_date.iso8601).to eq("2017-08-07")
    expect(work_package.due_date.iso8601).to eq("2017-08-07")
  end
end
