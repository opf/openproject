require "spec_helper"

RSpec.describe "Cost report calculations", :js, :with_cuprite do
  let(:project) { create(:project) }
  let(:user) { create(:admin) }

  before do
    login_as user
    visit cost_reports_path(project)
  end

  def clear_project_filter
    within "#filter_project_id" do
      find(".filter_rem").click
    end
  end

  def reload_page
    page.refresh
    wait_for_reload
  end

  it "provides filtering" do
    # Then filter "spent_on" should be visible
    # And filter "user_id" should be visible
    expect(page).to have_css("#filter_project_id")
    expect(page).to have_css("#filter_spent_on")
    expect(page).to have_css("#filter_user_id")

    # Regression #48633
    # Remove filter:
    # And I click on the filter's "Clear" button
    clear_project_filter
    # Then filter "project_id" should not be visible
    expect(page).to have_no_css("#filter_project_id")

    # Remove filters:
    # And I click on "Clear"
    click_on "Clear"
    # Then filter "spent_on" should not be visible
    # And filter "user_id" should not be visible
    expect(page).to have_no_css("#filter_spent_on")
    expect(page).to have_no_css("#filter_user_id")

    # Reload restores the query
    # And the user with the login "developer" should be selected for "User Value"
    # And "!" should be selected for "User Operator Open this filter with 'ALT' and arrow keys."
    reload_page
    expect(page).to have_css("#filter_spent_on")
    expect(page).to have_css("#filter_user_id")

    expect(page).to have_css("#user_id_arg_1_val", text: "me")
  end
end
