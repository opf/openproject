require "spec_helper"
require "support/pages/custom_fields"

RSpec.describe "custom fields", :js, :with_cuprite do
  let(:user) { create(:admin) }
  let(:cf_page) { Pages::CustomFields.new }

  before do
    login_as user
  end

  shared_examples "creating a new custom field" do |type|
    it "has the options in the right order for a list custom field" do
      cf_page.visit_tab type

      click_on "Create a new custom field"
      wait_for_reload
      cf_page.set_name "Operating System"

      select "List", from: "custom_field_field_format"
      expect(page).to have_text("Allow multi-select")
      check("custom_field_multi_value")

      expect(page).to have_css(".custom-option-row", count: 1)
      within all(".custom-option-row").last do
        find(".custom-option-value input").set "Windows"
        find(".custom-option-default-value input").set true
      end

      page.find_test_selector("add-custom-option").click

      expect(page).to have_css(".custom-option-row", count: 2)
      within all(".custom-option-row").last do
        find(".custom-option-value input").set "Linux"
      end

      page.find_test_selector("add-custom-option").click

      expect(page).to have_css(".custom-option-row", count: 3)
      within all(".custom-option-row").last do
        find(".custom-option-value input").set "Solaris"

        click_on "Move to top"
      end

      click_on "Save"

      expect(page).to have_text("Successful creation")

      click_on "Operating System"
      wait_for_reload

      expect(page).to have_field("custom_field_multi_value", checked: true)

      expect(page).to have_css(".custom-option-row", count: 3)
      expect(page).to have_field("custom_field_custom_options_attributes_0_value", with: "Solaris")
      expect(page).to have_field("custom_field_custom_options_attributes_1_value", with: "Windows")
      expect(page).to have_field("custom_field_custom_options_attributes_2_value", with: "Linux")

      expect(page).to have_field("custom_field_custom_options_attributes_0_default_value", checked: false)
      expect(page).to have_field("custom_field_custom_options_attributes_1_default_value", checked: true)
      expect(page).to have_field("custom_field_custom_options_attributes_2_default_value", checked: false)
    end

    it "shows the right options for each custom field type" do
      cf_page.visit_tab type

      click_on "Create a new custom field"
      wait_for_reload
      cf_page.set_name "Ignored"

      # Form element labels, default English translation in the trailing comment:
      label_min_length = I18n.t("activerecord.attributes.custom_field.min_length") # Minimum length
      label_max_length = I18n.t("activerecord.attributes.custom_field.max_length") # Maximum length
      label_regexp = I18n.t("activerecord.attributes.custom_field.regexp") # Regular expression
      label_multi_value = I18n.t("activerecord.attributes.custom_field.multi_value") # Allow multi-select
      label_allow_non_open_versions = I18n.t("activerecord.attributes.custom_field.allow_non_open_versions") # Allow non-open versions
      label_possible_values = I18n.t("activerecord.attributes.custom_field.possible_values").upcase # Possible values, capitalized on UI
      label_default_value = I18n.t("activerecord.attributes.custom_field.default_value") # Default value
      label_is_required = I18n.t("activerecord.attributes.custom_field.is_required") # Required
      # Spent time SFs don't show "Searchable". Not tested here.
      # Project CFs don't show "For all projects" and "Used as a filter". Not tested here.
      # Content right to left is not shown for Project CFs Long text. Strange. Not tested.

      def expect_page_to_have_texts(*text)
        text.each do |t|
          expect(page).to have_text(t)
        end
      end

      def expect_page_not_to_have_texts(*text)
        text.each do |t|
          expect(page).to have_no_text(t)
        end
      end

      select "Text", from: "custom_field_field_format"
      expect_page_to_have_texts(
        label_min_length, label_max_length, label_regexp, label_default_value, label_is_required
      )
      expect_page_not_to_have_texts(
        label_multi_value, label_allow_non_open_versions, label_possible_values
      )

      select "Long text", from: "custom_field_field_format"
      expect_page_to_have_texts(
        label_min_length, label_max_length, label_regexp, label_default_value, label_is_required
      )
      expect_page_not_to_have_texts(
        label_multi_value, label_allow_non_open_versions, label_possible_values
      )

      # Both Integer and Float have min/max_len and regex as well which seems strange.
      select "Integer", from: "custom_field_field_format"
      expect_page_to_have_texts(
        label_min_length, label_max_length, label_regexp, label_default_value, label_is_required
      )
      expect_page_not_to_have_texts(
        label_multi_value, label_allow_non_open_versions, label_possible_values
      )

      select "Float", from: "custom_field_field_format"
      expect_page_to_have_texts(
        label_min_length, label_max_length, label_regexp, label_default_value, label_is_required
      )
      expect_page_not_to_have_texts(
        label_multi_value, label_allow_non_open_versions, label_possible_values
      )

      select "List", from: "custom_field_field_format"
      expect_page_to_have_texts(
        label_multi_value, label_possible_values, label_is_required
      )
      expect_page_not_to_have_texts(
        label_min_length, label_max_length, label_regexp, label_allow_non_open_versions, label_default_value
      )

      select "Date", from: "custom_field_field_format"
      expect_page_to_have_texts(label_is_required)
      expect_page_not_to_have_texts(
        label_min_length, label_max_length, label_regexp, label_multi_value,
        label_allow_non_open_versions, label_possible_values, label_default_value
      )

      select "Boolean", from: "custom_field_field_format"
      expect_page_to_have_texts(
        label_default_value, label_is_required
      )
      expect_page_not_to_have_texts(
        label_min_length, label_max_length, label_regexp, label_multi_value,
        label_allow_non_open_versions, label_possible_values
      )

      select "User", from: "custom_field_field_format"
      expect_page_to_have_texts(
        label_multi_value, label_is_required
      )
      expect_page_not_to_have_texts(
        label_min_length, label_max_length, label_regexp, label_allow_non_open_versions,
        label_possible_values, label_default_value
      )

      select "Version", from: "custom_field_field_format"
      expect_page_to_have_texts(
        label_multi_value, label_allow_non_open_versions, label_is_required
      )
      expect_page_not_to_have_texts(
        label_min_length, label_max_length, label_regexp,
        label_possible_values, label_default_value
      )
    end

    it "shows the correct breadcrumbs" do
      cf_page.visit_tab type

      click_on "Create a new custom field"
      wait_for_reload

      page.within_test_selector("custom-fields--page-header") do
        expect(page).to have_css(".breadcrumb-item", text: type)
        expect(page).to have_css(".breadcrumb-item.breadcrumb-item-selected", text: "New custom field")
      end
    end
  end

  describe "work packages" do
    it_behaves_like "creating a new custom field", "Work packages"
  end

  describe "time entries" do
    it_behaves_like "creating a new custom field", "Spent time"
  end

  describe "versions" do
    it_behaves_like "creating a new custom field", "Versions"
  end

  context "with an existing list custom field" do
    let!(:custom_field) do
      create(
        :list_wp_custom_field,
        name: "Platform",
        possible_values: %w[Playstation Xbox Nintendo PC]
      )
    end

    before do
      cf_page.visit!
      wait_for_reload

      click_on custom_field.name
      wait_for_reload
    end

    it "adds new options" do
      page.find_test_selector("add-custom-option").click
      wait_for_reload

      expect(page).to have_css(".custom-option-row", count: 5)
      within all(".custom-option-row").last do
        find(".custom-option-value input").set "Sega"
      end

      page.find_test_selector("add-custom-option").click
      wait_for_reload

      expect(page).to have_css(".custom-option-row", count: 6)
      within all(".custom-option-row").last do
        find(".custom-option-value input").set "Atari"
      end

      click_on "Save"

      expect(page).to have_text("Successful update")
      expect(page).to have_text("Platform")
      expect(page).to have_css(".custom-option-row", count: 6)

      %w[Playstation Xbox Nintendo PC Sega Atari].each_with_index do |value, i|
        expect(page).to have_field("custom_field_custom_options_attributes_#{i}_value", with: value)
      end
    end

    it "updates the values and orders of the custom options" do
      expect(page).to have_text("Platform")

      expect(page).to have_css(".custom-option-row", count: 4)
      %w[Playstation Xbox Nintendo PC].each_with_index do |value, i|
        expect(page).to have_field("custom_field_custom_options_attributes_#{i}_value", with: value)
      end

      fill_in("custom_field_custom_options_attributes_1_value", with: "")
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

      %w[Sega Nintendo PC Playstation].each_with_index do |value, i|
        expect(page).to have_field("custom_field_custom_options_attributes_#{i}_value", with: value)
      end

      expect(page).to have_field("custom_field_custom_options_attributes_0_default_value", checked: false)
      expect(page).to have_field("custom_field_custom_options_attributes_1_default_value", checked: true)
      expect(page).to have_field("custom_field_custom_options_attributes_2_default_value", checked: false)
      expect(page).to have_field("custom_field_custom_options_attributes_3_default_value", checked: true)
    end

    it "shows the correct breadcrumbs" do
      page.within_test_selector("custom-fields--page-header") do
        expect(page).to have_css(".breadcrumb-item", text: "Work packages")
        expect(page).to have_css(".breadcrumb-item.breadcrumb-item-selected", text: "Platform")
      end
    end

    context "with work packages using the options" do
      before do
        create_list(
          :work_package_custom_value,
          3,
          custom_field:,
          value: custom_field.custom_options[1].id
        )
      end

      it "deletes a custom option and all values using it" do
        within all(".custom-option-row")[1] do
          accept_alert do
            find(".icon-delete").click
          end
        end

        expect(page).to have_text("Option 'Xbox' and its 3 occurrences were deleted.")

        rows = all(".custom-option-value input")

        expect(rows.size).to be(3)

        expect(rows[0].value).to eql("Playstation")
        expect(rows[1].value).to eql("Nintendo")
        expect(rows[2].value).to eql("PC")
      end
    end
  end
end
