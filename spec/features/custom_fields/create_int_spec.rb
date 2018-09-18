require 'spec_helper'
require 'support/pages/custom_fields'

describe 'custom fields', js: true do
  let(:user) { FactoryBot.create :admin }
  let(:cf_page) { Pages::CustomFields.new }

  before do
    login_as(user)
  end

  describe "creating a new float custom field" do
    before do
      cf_page.visit!

      click_on "Create a new custom field"
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
