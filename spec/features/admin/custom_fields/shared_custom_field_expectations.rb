# frozen_string_literal: true

# -- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
# ++

RSpec.shared_examples_for "list custom fields" do |type|
  let(:cf_page) { Pages::CustomFields::Index.new }
  let(:user) { create(:admin) }

  current_user { user }

  before do
    cf_page.visit_page type
  end

  it "has the options in the right order" do
    retry_block do
      cf_page.click_to_create_new_custom_field "List"
    end

    cf_page.set_name "Operating System"

    expect(page).to have_text("Allow multi-select")
    check("multi_value")

    click_on "Save"
    cf_page.expect_flash(message: "Successful creation.")
    expect(page).to have_field("multi_value", checked: true)

    click_link "Items"
    wait_for_network_idle

    expect(page).to have_css(".custom-option-row", count: 1)
    within all(".custom-option-row").last do
      find(".custom-option-value input").set "Windows"
      find(".custom-option-default-value input").set true
    end

    retry_block do
      page.find_test_selector("add-custom-option").click

      expect(page).to have_css(".custom-option-row", count: 2)
    end

    within all(".custom-option-row").last do
      find(".custom-option-value input").set "Linux"
    end

    retry_block do
      page.find_test_selector("add-custom-option").click

      expect(page).to have_css(".custom-option-row", count: 3)
    end

    within all(".custom-option-row").last do
      find(".custom-option-value input").set "Solaris"

      click_on accessible_name: "Move to top"
    end

    click_on "Save"

    expect(page).to have_css(".custom-option-row", count: 3)
    expect(page).to have_field("custom_field_custom_options_attributes_0_value", with: "Solaris")
    expect(page).to have_field("custom_field_custom_options_attributes_1_value", with: "Windows")
    expect(page).to have_field("custom_field_custom_options_attributes_2_value", with: "Linux")

    expect(page).to have_field("custom_field_custom_options_attributes_0_default_value", checked: false)
    expect(page).to have_field("custom_field_custom_options_attributes_1_default_value", checked: true)
    expect(page).to have_field("custom_field_custom_options_attributes_2_default_value", checked: false)
  end
end

RSpec.shared_examples_for "hierarchy custom fields on index page" do |type|
  let(:cf_page) { Pages::CustomFields::Index.new }
  let(:user) { create(:admin) }

  current_user { user }

  before do
    cf_page.visit_page type
  end

  context "with an active enterprise token with custom_field_hierarchies feature", with_ee: [:custom_field_hierarchies] do
    it "does not show the enterprise upsell banner and has the 'Hierarchy' option for creation" do
      expect(page).to have_no_text(I18n.t("ee.upsell.custom_field_hierarchies.description"))
      cf_page.expect_having_create_item "Hierarchy"
    end
  end

  context "with an active enterprise token without custom_field_hierarchies feature", with_ee: [:another_feature] do
    it "shows the enterprise upsell banner and lacks the 'Hierarchy' option for creation" do
      expect(page).to have_text(I18n.t("ee.upsell.custom_field_hierarchies.description"))
      cf_page.expect_not_having_create_item "Hierarchy"
    end
  end

  context "with a trial enterprise token", :with_ee_trial, with_ee: [:custom_field_hierarchies] do
    it "shows the enterprise upsell banner and has the 'Hierarchy' option for creation" do
      expect(page).to have_text(I18n.t("ee.upsell.custom_field_hierarchies.description"))
      cf_page.expect_having_create_item "Hierarchy"
    end
  end
end

RSpec.shared_examples_for "expected fields for the custom field's format", :aggregate_failures do |type_plural, format|
  let(:type) { type_plural.singularize }
  let(:cf_page) { Pages::CustomFields::Index.new }
  let(:user) { create(:admin) }

  current_user { user }

  before do
    cf_page.visit_page type_plural
  end

  def expect_page_to_have(selectors)
    selectors.each do |selector, locators|
      Array(locators).each do |locator|
        expect(page).to send("have_#{selector}".singularize, locator)
      end
    end
  end

  # Form element labels, default English translation in the trailing comment:
  let(:label_name) { I18n.t("attributes.name") } # Name
  let(:label_section) { I18n.t("activerecord.attributes.project_custom_field.custom_field_section") } # Section
  let(:label_has_comment) { I18n.t("activerecord.attributes.custom_field.has_comment") } # Add a comment text field
  let(:label_is_for_all) { I18n.t("attributes.is_for_all") } # For all projects
  let(:label_admin_only) { I18n.t("activerecord.attributes.custom_field.admin_only") } # Admin-only
  let(:label_searchable) { I18n.t("activerecord.attributes.custom_field.searchable") } # Searchable
  let(:label_is_filter) { I18n.t("activerecord.attributes.custom_field.is_filter") } # Used as a filter
  let(:label_content_right_to_left) do # Right-to-Left content
    I18n.t("activerecord.attributes.custom_field.content_right_to_left")
  end
  let(:label_editable) { I18n.t("activerecord.attributes.custom_field.editable") } # Editable
  let(:label_min_length) { I18n.t("activerecord.attributes.custom_field.min_length") } # Minimum length
  let(:label_max_length) { I18n.t("activerecord.attributes.custom_field.max_length") } # Maximum length
  let(:label_regexp) { I18n.t("activerecord.attributes.custom_field.regexp") } # Regular expression
  let(:label_multi_value) { I18n.t("activerecord.attributes.custom_field.multi_value") } # Allow multi-select
  let(:label_allow_non_open_versions) do # Allow non-open versions
    I18n.t("activerecord.attributes.custom_field.allow_non_open_versions")
  end
  let(:label_possible_values) do # Possible values
    I18n.t("activerecord.attributes.custom_field.possible_values")
  end
  let(:label_default_value) { I18n.t("activerecord.attributes.custom_field.default_value") } # Default value
  let(:label_is_required) { I18n.t("activerecord.attributes.custom_field.is_required") } # Required
  let(:label_formula) { I18n.t("activerecord.attributes.custom_field.formula") } # Formula

  it "shows the right options for the #{format} custom field type" do
    retry_block do
      cf_page.click_to_create_new_custom_field format
    end

    expect(page).to have_field(label_name)

    if type == "Project"
      expect(page).to have_field(label_section)
    else
      expect(page).to have_no_label(label_section)
    end

    if type == "Project"
      expect(page).to have_field(label_has_comment)
    else
      expect(page).to have_no_label(label_has_comment)
    end

    if type == "Work package"
      expect(page).to have_field(label_is_filter)
    else
      expect(page).to have_no_label(label_is_filter)
    end

    if type == "Work package" && format != "Hierarchy"
      expect(page).to have_field(label_content_right_to_left)
    else
      expect(page).to have_no_label(label_content_right_to_left)
    end

    if type == "User"
      expect(page).to have_field(label_editable)
    else
      expect(page).to have_no_label(label_editable)
    end

    if type in "Work package" | "Project"
      expect(page).to have_field(label_is_for_all)
    else
      expect(page).to have_no_label(label_is_for_all)
    end

    if (type in "Work package" | "Project") && (format in "Text" | "Long text" | "Link" | "List")
      expect(page).to have_field(label_searchable)
    else
      expect(page).to have_no_label(label_searchable)
    end

    if type in "User" | "Project"
      expect(page).to have_field(label_admin_only)
    else
      expect(page).to have_no_label(label_admin_only)
    end

    if format in "Text" | "Integer" | "Float" | "Long text"
      expect_page_to_have(fields: [
                            label_min_length,
                            label_max_length
                          ])
    else
      expect_page_to_have(no_labels: [
                            label_min_length,
                            label_max_length
                          ])
    end

    # Integer and Float have min/max_len and regex as well which seems strange.
    if format in "Text" | "Integer" | "Float" | "Long text" | "Link"
      expect(page).to have_field(label_regexp)
    else
      expect(page).to have_no_label(label_regexp)
    end

    case format
    in "Text" | "Integer" | "Float" | "Link"
      expect(page).to have_field(label_default_value, type: "text")
    in "Boolean"
      expect(page).to have_field(label_default_value, type: "checkbox")
    in "Long text"
      expect(page).to have_rich_text_field(label_default_value)
    else
      expect(page).to have_no_label(label_default_value)
    end

    if format in "List" | "User" | "Version" | "Hierarchy"
      expect(page).to have_field(label_multi_value)
    else
      expect(page).to have_no_label(label_multi_value)
    end

    if format in "Boolean" | "Calculated value"
      expect(page).to have_no_label(label_is_required)
    else
      expect(page).to have_field(label_is_required)
    end

    if format == "Calculated value"
      expect(page).to have_pattern_input(label_formula)
    else
      expect(page).to have_no_label(label_formula)
    end

    if format == "Version"
      expect(page).to have_field(label_allow_non_open_versions)
    else
      expect(page).to have_no_label(label_allow_non_open_versions)
    end
  end
end
