require "spec_helper"

RSpec.describe "Work Package highlighting fields", :js,
               with_ee: %i[conditional_highlighting] do
  let(:user) { create(:admin) }

  let(:project) { create(:project) }

  let(:status1) { create(:status, color: create(:color, hexcode: "#FF0000")) } # rgba(255, 0, 0, 1)
  let(:status2) { create(:status, color: create(:color, hexcode: "#F0F0F0")) } # rgba(240, 240, 240, 1)

  let(:priority1) do
    create(:issue_priority, color: create(:color, hexcode: "#123456"))
  end
  let(:priority_no_color) { create(:issue_priority, color: nil) }

  let!(:wp_1) do
    create(:work_package,
           project:,
           status: status1,
           subject: "B",
           due_date: (Date.today - 1.day),
           priority: priority1)
  end

  let!(:wp_2) do
    create(:work_package,
           project:,
           status: status2,
           subject: "A",
           due_date: Date.today,
           priority: priority_no_color)
  end

  let(:wp_table) { Pages::WorkPackagesTable.new(project) }
  let(:highlighting) { Components::WorkPackages::Highlighting.new }
  let(:sort_by) { Components::WorkPackages::SortBy.new }
  let(:query_title) { Components::WorkPackages::QueryTitle.new }

  let!(:query) do
    query = build(:query, user:, project:)
    query.column_names = %w[id subject status priority due_date]
    query.highlighted_attributes = %i[status priority due_date]
    query.highlighting_mode = :inline

    query.save!
    query
  end

  before do
    # Ensure Rails and Capybara caches are cleared
    Rails.cache.clear
    Capybara.reset!
    allow(EnterpriseToken).to receive(:show_banners?).and_return(false)
    login_as(user)
    wp_table.visit_query query
    wp_table.expect_work_package_listed wp_1, wp_2
  end

  it "provides highlighting through css classes" do
    # Default inline highlight
    wp1_row = wp_table.row(wp_1)
    wp2_row = wp_table.row(wp_2)

    ## Status
    expect(SelectorHelpers.get_pseudo_class_property(page,
                                                     wp1_row.find('[class^="__hl_inline_status_"]'),
                                                     ":before",
                                                     "background-color")).to eq("rgb(255, 0, 0)")
    expect(SelectorHelpers.get_pseudo_class_property(page,
                                                     wp2_row.find('[class^="__hl_inline_status_"]'),
                                                     ":before",
                                                     "background-color")).to eq("rgb(240, 240, 240)")

    ## Priority
    expect(SelectorHelpers.get_pseudo_class_property(page,
                                                     wp1_row.find('[class^="__hl_inline_priority_"]'),
                                                     ":before",
                                                     "background-color")).to eq("rgb(18, 52, 86)")
    expect(SelectorHelpers.get_pseudo_class_property(page,
                                                     wp2_row.find('[class^="__hl_inline_priority_"]'),
                                                     ":before",
                                                     "background-color")).to eq("rgba(0, 0, 0, 0)")

    ## Overdue
    expect(wp1_row).to have_css(".__hl_date_overdue")
    expect(wp2_row).to have_css(".__hl_date_due_today")

    # Highlight only one attribute
    highlighting.switch_inline_attribute_highlight "Priority"

    wp1_row = wp_table.row(wp_1)
    wp2_row = wp_table.row(wp_2)

    ## Priority should have a dot
    expect(SelectorHelpers.get_pseudo_class_property(page,
                                                     wp1_row.find('[class^="__hl_inline_priority_"]'),
                                                     ":before",
                                                     "background-color")).to eq("rgb(18, 52, 86)")
    expect(SelectorHelpers.get_pseudo_class_property(page,
                                                     wp2_row.find('[class^="__hl_inline_priority_"]'),
                                                     ":before",
                                                     "background-color")).to eq("rgba(0, 0, 0, 0)")

    ## Status should not have a dot
    expect(wp1_row).to have_no_css('.status [class^="__hl_inline_"]')

    # Highlight multiple attributes
    highlighting.switch_inline_attribute_highlight "Priority", "Status"
    wp1_row = wp_table.row(wp_1)
    expect(SelectorHelpers.get_pseudo_class_property(page,
                                                     wp1_row.find('[class^="__hl_inline_priority_"]'),
                                                     ":before",
                                                     "background-color")).to eq("rgb(18, 52, 86)")
    expect(SelectorHelpers.get_pseudo_class_property(page,
                                                     wp1_row.find('[class^="__hl_inline_status_"]'),
                                                     ":before",
                                                     "background-color")).to eq("rgb(255, 0, 0)")

    # Highlight entire row by status
    highlighting.switch_entire_row_highlight "Status"
    expect(page).to have_css("#{wp_table.row_selector(wp_1)}.__hl_background_status_#{status1.id}")
    expect(page).to have_css("#{wp_table.row_selector(wp_2)}.__hl_background_status_#{status2.id}")

    # Unselect all rows to ensure we get the correct background
    find("body").send_keys [:control, "d"]

    wp1_row = wp_table.row(wp_1)
    wp2_row = wp_table.row(wp_2)
    expect(wp1_row.native.css_value("background-color")).to eq("rgba(255, 0, 0, 1)")
    expect(wp2_row.native.css_value("background-color")).to eq("rgba(240, 240, 240, 1)")

    # Save query
    wp_table.save
    wp_table.expect_and_dismiss_toaster message: "Successful update."
    query.reload
    expect(query.highlighting_mode).to eq(:status)

    ## This disables any inline styles
    expect(page).to have_no_css('[class*="__hl_inline_status"]')
    expect(page).to have_no_css('[class*="__hl_inline_priority"]')
    expect(page).to have_no_css('[class*="__hl_date"]')

    # Highlight entire row by priority
    highlighting.switch_entire_row_highlight "Priority"
    expect(page).to have_css("#{wp_table.row_selector(wp_1)}.__hl_background_priority_#{priority1.id}")
    expect(page).to have_css("#{wp_table.row_selector(wp_2)}.__hl_background_priority_#{priority_no_color.id}")

    # Remove selection from table row
    find("body").send_keys [:control, "d"]

    wp1_row = wp_table.row(wp_1)
    wp2_row = wp_table.row(wp_2)
    expect(wp1_row.native.css_value("background-color")).to eq("rgba(18, 52, 86, 1)")
    expect(wp2_row.native.css_value("background-color")).to eq("rgba(0, 0, 0, 0)")

    # Highlighting is kept even after a hard reload (Regression #30217)
    page.driver.refresh
    expect(page).to have_css("#{wp_table.row_selector(wp_1)}.__hl_background_priority_#{priority1.id}")
    expect(page).to have_css("#{wp_table.row_selector(wp_2)}.__hl_background_priority_#{priority_no_color.id}")
    expect(page).to have_no_css('[class*="__hl_inline_status"]')
    expect(page).to have_no_css('[class*="__hl_inline_priority"]')
    expect(page).to have_no_css('[class*="__hl_date"]')

    # Save query
    wp_table.save
    wp_table.expect_and_dismiss_toaster message: "Successful update."
    query.reload
    expect(query.highlighting_mode).to eq(:priority)

    ## This disables any inline styles
    expect(page).to have_no_css('[class*="__hl_inline_status"]')
    expect(page).to have_no_css('[class*="__hl_inline_priority"]')
    expect(page).to have_no_css('[class*="__hl_date"]')

    # No highlighting
    highlighting.switch_highlighting_mode "No highlighting"
    expect(page).to have_no_css('[class*="__hl_background"]')
    expect(page).to have_no_css('[class*="__hl_background_status"]')
    expect(page).to have_no_css('[class*="__hl_background_priority"]')
    expect(page).to have_no_css('[class*="__hl_date"]')

    # Save query
    wp_table.save
    wp_table.expect_and_dismiss_toaster message: "Successful update."
    query.reload
    expect(query.highlighting_mode).to eq(:none)

    wp_table.expect_work_package_listed(wp_1, wp_2)

    # Expect highlighted fields in single view even when table disabled
    wp_table.open_full_screen_by_doubleclick wp_1
    expect(page).to have_css("#{test_selector('op-wp-status-button')} .__hl_background_status_#{status1.id}")
    expect(page).to have_css(".__hl_inline_priority_#{priority1.id}")
  end

  it "correctly parses custom selected inline attributes", :with_cuprite do
    # Highlight only one attribute
    highlighting.switch_inline_attribute_highlight "Priority"

    # Regression test, resort table
    sort_by.sort_via_header "Subject"
    wp_table.expect_work_package_order wp_2, wp_1

    # Regression test, resort table
    sort_by.sort_via_header "Subject", descending: true
    wp_table.expect_work_package_order wp_1, wp_2
  end

  it "does not set query_props when switching in view (Regression #32118)" do
    prio_wp1 = wp_table.edit_field(wp_1, :priority)
    prio_wp1.update priority_no_color.name
    prio_wp1.expect_state_text priority_no_color.name

    wp_table.expect_and_dismiss_toaster message: "Successful update."
    wp_1.reload
    expect(wp_1.priority).to eq priority_no_color

    # We need to wait a bit for the query_props to load
    # I don't have a better idea than waiting explicitly here
    sleep 5

    query_title.expect_not_changed

    url = URI.parse(page.current_url).query
    expect(url).to include("query_id=#{query.id}")
    expect(url).not_to match(/query_props=.+/)
  end
end
