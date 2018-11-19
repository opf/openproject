require 'spec_helper'

describe 'Cost report calculations', type: :feature, js: true do
  let(:project) { FactoryBot.create :project }
  let(:user) { FactoryBot.create :admin }

  before do
    login_as(user)
    visit cost_reports_path(project)
  end

  it 'provides filtering' do
    # Then filter "spent_on" should be visible
    # And filter "user_id" should be visible
    expect(page).to have_selector("#filter_spent_on")
    expect(page).to have_selector("#filter_user_id")

    # Remove filter:
    # And I click on "Clear"
    click_on 'Clear'
    # Then filter "spent_on" should not be visible
    # And filter "user_id" should not be visible
    expect(page).to have_no_selector("#filter_spent_on")
    expect(page).to have_no_selector("#filter_user_id")

    # Reload restores the query
    # And the user with the login "developer" should be selected for "User Value"
    # And "!" should be selected for "User Operator Open this filter with 'ALT' and arrow keys."
    visit cost_reports_path(project)
    expect(page).to have_selector("#filter_spent_on")
    expect(page).to have_selector("#filter_user_id")

    expect(page).to have_selector("#user_id_arg_1_val", text: 'me')
  end
end