require "spec_helper"
require "support/pages/custom_fields/index_page"

RSpec.describe "custom fields", :js, :with_cuprite do
  let(:user) { create(:admin) }
  let(:cf_page) { Pages::CustomFields::IndexPage.new }

  before do
    login_as user
  end

  describe "creating a new float custom field" do
    before do
      cf_page.visit!

      click_on "Create a new custom field"
      wait_for_reload
    end

    it "creates a new float custom field" do
      cf_page.set_name "New Field"
      cf_page.select_format "Integer"
      cf_page.set_default_value "342"
      click_on "Save"

      expect(page).to have_text("Successful creation")
      expect(page).to have_text("New Field")
    end
  end
end
