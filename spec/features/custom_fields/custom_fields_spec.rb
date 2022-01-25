require 'spec_helper'
require 'support/pages/custom_fields'

describe 'custom fields', js: true do
  let(:user) { create :admin }
  let(:cf_page) { Pages::CustomFields.new }

  before do
    login_as(user)
  end

  shared_examples "creating a new list custom field" do |type|
    it "creates a new list custom field with its options in the right order" do
      cf_page.visit_tab type

      click_on "Create a new custom field"
      cf_page.set_name "Operating System"

      select "List", from: "custom_field_field_format"
      expect(page).to have_text("Allow multi-select")

      expect(page).to have_selector('.custom-option-row', count: 1)
      within all(".custom-option-row").last do
        find(".custom-option-value input").set "Windows"
        find(".custom-option-default-value input").set true
      end

      click_on "add-custom-option"

      expect(page).to have_selector('.custom-option-row', count: 2)
      within all(".custom-option-row").last do
        find(".custom-option-value input").set "Linux"
      end

      click_on "add-custom-option"

      expect(page).to have_selector('.custom-option-row', count: 3)
      within all(".custom-option-row").last do
        find(".custom-option-value input").set "Solaris"

        click_on "Move to top"
      end

      click_on "Save"

      expect(page).to have_text("Successful creation")

      SeleniumHubWaiter.wait
      click_on "Operating System"

      expect(page).to have_selector('.custom-option-row', count: 3)
      expect(page).to have_field("custom_field_custom_options_attributes_0_value", with: "Solaris")
      expect(page).to have_field("custom_field_custom_options_attributes_1_value", with: "Windows")
      expect(page).to have_field("custom_field_custom_options_attributes_2_value", with: "Linux")

      expect(page).to have_field("custom_field_custom_options_attributes_0_default_value", checked: false)
      expect(page).to have_field("custom_field_custom_options_attributes_1_default_value", checked: true)
      expect(page).to have_field("custom_field_custom_options_attributes_2_default_value", checked: false)
    end
  end

  describe 'projects' do
    it_behaves_like "creating a new list custom field", 'Projects'
  end

  describe 'work packages' do
    it_behaves_like "creating a new list custom field", 'Work packages'
  end

  context "with an existing list custom field" do
    let!(:custom_field) do
      create(
        :list_wp_custom_field,
        name: "Platform",
        possible_values: ["Playstation", "Xbox", "Nintendo", "PC"]
      )
    end

    before do
      with_enterprise_token(:multiselect_custom_fields)

      cf_page.visit!
      expect_angular_frontend_initialized
      SeleniumHubWaiter.wait

      click_on custom_field.name
      expect_angular_frontend_initialized
      SeleniumHubWaiter.wait
    end

    it "adds new options" do
      click_on "add-custom-option"
      SeleniumHubWaiter.wait

      expect(page).to have_selector('.custom-option-row', count: 5)
      within all(".custom-option-row").last do
        find(".custom-option-value input").set "Sega"
      end

      click_on "add-custom-option"
      SeleniumHubWaiter.wait

      expect(page).to have_selector('.custom-option-row', count: 6)
      within all(".custom-option-row").last do
        find(".custom-option-value input").set "Atari"
      end

      click_on "Save"

      expect(page).to have_text("Successful update")
      expect(page).to have_text("Platform")
      expect(page).to have_selector('.custom-option-row', count: 6)

      ["Playstation", "Xbox", "Nintendo", "PC", "Sega", "Atari"].each_with_index do |value, i|
        expect(page).to have_field("custom_field_custom_options_attributes_#{i}_value", with: value)
      end
    end

    it "updates the values and orders of the custom options" do
      expect(page).to have_text("Platform")

      expect(page).to have_selector('.custom-option-row', count: 4)
      ["Playstation", "Xbox", "Nintendo", "PC"].each_with_index do |value, i|
        expect(page).to have_field("custom_field_custom_options_attributes_#{i}_value", with: value)
      end

      fill_in("custom_field_custom_options_attributes_1_value", with: "Sega")
      check("custom_field_multi_value")
      check("custom_field_custom_options_attributes_0_default_value")
      check("custom_field_custom_options_attributes_2_default_value")
      within all(".custom-option-row").first do
        click_on "Move to bottom"
      end
      click_on "Save"

      expect(page).to have_text("Successful update")
      expect(page).to have_text("Platform")
      expect(page).to have_field("custom_field_multi_value", checked: true)

      ["Sega", "Nintendo", "PC", "Playstation"].each_with_index do |value, i|
        expect(page).to have_field("custom_field_custom_options_attributes_#{i}_value", with: value)
      end

      expect(page).to have_field("custom_field_custom_options_attributes_0_default_value", checked: false)
      expect(page).to have_field("custom_field_custom_options_attributes_1_default_value", checked: true)
      expect(page).to have_field("custom_field_custom_options_attributes_2_default_value", checked: false)
      expect(page).to have_field("custom_field_custom_options_attributes_3_default_value", checked: true)
    end

    context "with work packages using the options" do
      before do
        create_list(
          :work_package_custom_value,
          3,
          custom_field: custom_field,
          value: custom_field.custom_options[1].id
        )
      end

      it "deletes a custom option and all values using it" do
        within all(".custom-option-row")[1] do
          find('.icon-delete').click

          cf_page.accept_alert_dialog!
        end

        expect(page).to have_text("Option 'Xbox' and its 3 occurrences were deleted.")

        rows = all(".custom-option-value input")

        expect(rows.size).to eql(3)

        expect(rows[0].value).to eql("Playstation")
        expect(rows[1].value).to eql("Nintendo")
        expect(rows[2].value).to eql("PC")
      end
    end
  end
end
