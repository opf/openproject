require 'spec_helper'
require 'support/pages/custom_fields'

describe 'custom fields', js: true do
  let(:user) { FactoryGirl.create :admin }
  let(:cf_page) { Pages::CustomFields.new }

  before do
    login_as(user)
  end

  describe "creating a new list custom field" do
    before do
      cf_page.visit!

      click_on "Create a new custom field"
    end

    it "creates a new list custom field with its options in the right order" do
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

      click_on "Operating System"

      expect(page).to have_selector('.custom-option-row', count: 3)
      values = all(".custom-option-value input")

      expect(values[0].value).to eql("Solaris")
      expect(values[1].value).to eql("Windows")
      expect(values[2].value).to eql("Linux")

      defaults = all(".custom-option-default-value input")

      expect(defaults[0]).not_to be_checked
      expect(defaults[1]).to be_checked
      expect(defaults[2]).not_to be_checked
    end
  end

  context "with an existing list custom field" do
    let!(:custom_field) do
      FactoryGirl.create(
        :list_wp_custom_field,
        name: "Platform",
        possible_values: ["Playstation", "Xbox", "Nintendo", "PC"]
      )
    end

    before do
      allow(EnterpriseToken).to receive(:allows_to?).and_return(true)

      cf_page.visit!

      click_on custom_field.name
    end

    it "adds new options" do
      click_on "add-custom-option"

      expect(page).to have_selector('.custom-option-row', count: 5)
      within all(".custom-option-row").last do
        find(".custom-option-value input").set "Sega"
      end

      click_on "add-custom-option"

      expect(page).to have_selector('.custom-option-row', count: 6)
      within all(".custom-option-row").last do
        find(".custom-option-value input").set "Atari"
      end

      click_on "Save"

      expect(page).to have_text("Successful update")
      expect(page).to have_text("Platform")
      expect(page).to have_selector('.custom-option-row', count: 6)

      values = all(".custom-option-value input").map(&:value)

      expect(values).to eq ["Playstation", "Xbox", "Nintendo", "PC", "Sega", "Atari"]
    end

    it "updates the values and orders of the custom options" do
      expect(page).to have_text("Platform")

      expect(page).to have_selector('.custom-option-row', count: 4)
      rows = all(".custom-option-value input")

      expect(rows[0].value).to eql("Playstation")
      expect(rows[1].value).to eql("Xbox")
      expect(rows[2].value).to eql("Nintendo")
      expect(rows[3].value).to eql("PC")

      rows[1].set "Sega"

      find("#custom_field_multi_value").set true

      defaults = all(".custom-option-default-value input")

      defaults[0].set true
      defaults[2].set true

      within all(".custom-option-row").first do
        click_on "Move to bottom"
      end

      click_on "Save"

      expect(page).to have_text("Successful update")
      expect(page).to have_text("Platform")

      expect(find("#custom_field_multi_value")).to be_checked

      new_rows = all(".custom-option-value input")

      expect(new_rows[0].value).to eql("Sega")
      expect(new_rows[1].value).to eql("Nintendo")
      expect(new_rows[2].value).to eql("PC")
      expect(new_rows[3].value).to eql("Playstation")

      new_defaults = all(".custom-option-default-value input")

      expect(new_defaults[0]).not_to be_checked
      expect(new_defaults[1]).to be_checked
      expect(new_defaults[2]).not_to be_checked
      expect(new_defaults[3]).to be_checked
    end

    context "with work packages using the options" do
      before do
        FactoryGirl.create_list(
          :work_package_custom_value,
          3,
          custom_field: custom_field,
          value: custom_field.custom_options[1].id
        )
      end

      it "deletes a custom option and all values using it" do
        within all(".custom-option-row")[1] do
          click_on "Delete"

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
