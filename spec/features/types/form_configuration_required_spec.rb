# frozen_string_literal: true

#-- copyright
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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe "form configuration required attributes", :js do
  shared_let(:admin) { create(:admin) }

  let(:custom_field) { create(:integer_wp_custom_field, name: "Impact") }
  let(:form) { Components::Admin::TypeConfigurationForm.new }

  let(:mark) { I18n.t("types.edit.form_configuration.required.mark") }
  let(:unmark) { I18n.t("types.edit.form_configuration.required.unmark") }
  let(:globally_label) { I18n.t("types.edit.form_configuration.required.globally") }
  let(:in_type_label) { I18n.t("types.edit.form_configuration.required.for_variant") }

  def variant_showing(field, type: create(:type))
    type.default_variant.tap do |variant|
      variant.attribute_groups = [["Details", [field.attribute_name, "priority"]]]
      variant.custom_field_ids = [field.id]
      variant.save!
    end
  end

  def required_action(attribute)
    page.find_test_selector("type-form-configuration-toggle-required-#{attribute}")
  end

  def click_required_action(attribute, label)
    page.find_test_selector("type-form-configuration-toggle-required-#{attribute}", text: label).click
  end

  def required_badge(attribute)
    page.test_selector("type-form-configuration-required-#{attribute}")
  end

  # The two labels differ in color as well as wording, and "Required" is a substring of
  # "Required in this type", so both are asserted exactly.
  def expect_badge(attribute, text:, scheme:)
    badge = page.find_test_selector("type-form-configuration-required-#{attribute}")

    expect(badge.text).to eq(text)
    expect(badge[:class]).to include("Label--#{scheme}")
  end

  before { login_as admin }

  context "with a custom field the field itself leaves optional" do
    let!(:variant) { variant_showing(custom_field) }
    let!(:other_variant) { variant_showing(custom_field, type: create(:type, name: "Other type")) }

    before { visit edit_type_form_configuration_path(type_id: variant.type_id) }

    it "marks the field required for this type only" do
      expect(page).to have_text("Impact")
      expect(page).to have_no_css(required_badge(custom_field.attribute_name))

      click_required_action(custom_field.attribute_name, mark)

      expect_badge(custom_field.attribute_name, text: in_type_label, scheme: "severe")
      expect(variant.reload.required_attributes).to contain_exactly(custom_field.attribute_name)

      expect(other_variant.reload.required_attributes).to eq([])

      visit edit_type_form_configuration_path(type_id: other_variant.type_id)

      expect(page).to have_text("Impact")
      expect(page).to have_no_css(required_badge(custom_field.attribute_name))
      expect(required_action(custom_field.attribute_name)).to have_text(mark)
    end

    it "makes the field optional again" do
      click_required_action(custom_field.attribute_name, mark)
      expect(page).to have_css(required_badge(custom_field.attribute_name))

      click_required_action(custom_field.attribute_name, unmark)

      expect(page).to have_no_css(required_badge(custom_field.attribute_name))
      expect(variant.reload.required_attributes).to eq([])
    end

    it "offers nothing for a built-in attribute" do
      expect(page).to have_text("Priority")
      expect(page).to have_no_test_selector("type-form-configuration-toggle-required-priority")
    end

    it "places the action left of the exclusion toggle" do
      action = required_action(custom_field.attribute_name)
      toggle = page.find_test_selector("toggle-form-config-exclusion-#{custom_field.attribute_name}")

      expect(action.rect["right"]).to be <= toggle.rect["left"]
    end
  end

  context "with a globally required custom field" do
    let(:custom_field) { create(:integer_wp_custom_field, name: "Impact", is_required: true) }
    let!(:variant) { variant_showing(custom_field) }

    before { visit edit_type_form_configuration_path(type_id: variant.type_id) }

    it "says so and disables the action, naming where the setting lives" do
      expect_badge(custom_field.attribute_name, text: globally_label, scheme: "attention")

      action = required_action(custom_field.attribute_name)

      expect(action).to have_text(mark)
      expect(action.tag_name).to eq("button")
      expect(action[:"aria-disabled"]).to eq("true")

      action.hover
      expect(page).to have_css("tool-tip[for='#{action[:id]}']",
                               text: I18n.t("types.edit.form_configuration.required.globally_hint"))

      action.click
      expect(variant.reload.required_attributes).to eq([])
    end
  end

  context "with a variant sharing its type's form" do
    let!(:owner) { variant_showing(custom_field) }
    let!(:sharer) { create(:type_variant, type: owner.type, form_configuration: owner.form_configuration) }

    before do
      owner.update!(required_attributes: [custom_field.attribute_name])
      visit edit_type_variant_form_configuration_path(type_id: sharer.type_id, variant_id: sharer.id)
    end

    it "keeps a required list of its own" do
      expect(page).to have_text("Impact")
      expect(page).to have_no_css(required_badge(custom_field.attribute_name))

      click_required_action(custom_field.attribute_name, mark)

      expect_badge(custom_field.attribute_name, text: in_type_label, scheme: "severe")
      expect(sharer.reload.required_attributes).to contain_exactly(custom_field.attribute_name)
      expect(owner.reload.required_attributes).to contain_exactly(custom_field.attribute_name)
    end
  end
end
