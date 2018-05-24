require 'spec_helper'
require 'support/pages/custom_fields'

describe 'custom fields', js: true do
  let(:user) { FactoryBot.create :admin }
  let(:cf_page) { Pages::CustomFields.new }

  before do
    login_as(user)
  end

  describe "available fields" do
    before do
      cf_page.visit!
      click_on "Create a new custom field"
    end

    it "shows all form elements" do
      expect(cf_page).to have_form_element("Name")
      expect(cf_page).to have_form_element("Required")
      expect(cf_page).to have_form_element("For all projects")
      expect(cf_page).to have_form_element("Used as a filter")
      expect(cf_page).to have_form_element("Searchable")
    end
  end

  describe "creating a new bool custom field" do
    before do
      cf_page.visit!
      click_on "Create a new custom field"
    end

    it "creates a new bool custom field" do
      cf_page.set_name "New Field"
      cf_page.select_format "Date"
      click_on "Save"

      expect(page).to have_text("Successful creation")
      expect(page).to have_text("New Field")
    end
  end
end
