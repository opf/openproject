require "spec_helper"

RSpec.describe "Errors handling" do
  it "renders the internal error page in case of exceptions" do
    # We unfortunately cannot test raising exceptions as the test environment
    # marks all requests as local and thus shows exception details instead (like in dev mode)
    visit "/500"
    expect(page).to have_current_path "/500"
    expect(page).to have_text "An error occurred on the page you were trying to access."
    expect(page).to have_no_text "Oh no, this is an internal error!"
  end

  it "renders the not found page" do
    # We unfortunately cannot test raising exceptions as the test environment
    # marks all requests as local and thus shows exception details instead (like in dev mode)
    visit "/404"
    expect(page).to have_current_path "/404"
    expect(page).to have_text "[Error 404] The page you were trying to access doesn't exist or has been removed."
  end

  it "renders the unacceptable response" do
    # This file exists in public and is recommended to be rendered, but I'm not aware
    # of any path that would trigger this
    visit "/422"
    expect(page).to have_current_path "/422"
    expect(page).to have_text "The change you wanted was rejected."
  end
end
