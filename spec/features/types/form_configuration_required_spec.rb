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

  def required_badge(attribute)
    page.test_selector("type-form-configuration-required-#{attribute}")
  end

  # The two labels differ in colour as well as wording, and "Required" is a substring of
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

      form.invoke_attribute_action(custom_field.attribute_name, mark)

      expect_badge(custom_field.attribute_name, text: in_type_label, scheme: "severe")
      expect(variant.reload.required_attributes).to contain_exactly(custom_field.attribute_name)

      expect(other_variant.reload.required_attributes).to eq([])

      visit edit_type_form_configuration_path(type_id: other_variant.type_id)

      expect(page).to have_text("Impact")
      expect(page).to have_no_css(required_badge(custom_field.attribute_name))
      form.open_attribute_menu(custom_field.attribute_name)
      expect(page).to have_text(mark)
    end

    it "makes the field optional again" do
      form.invoke_attribute_action(custom_field.attribute_name, mark)
      expect(page).to have_css(required_badge(custom_field.attribute_name))

      form.invoke_attribute_action(custom_field.attribute_name, unmark)

      expect(page).to have_no_css(required_badge(custom_field.attribute_name))
      expect(variant.reload.required_attributes).to eq([])
    end

    it "offers nothing for a built-in attribute" do
      form.open_attribute_menu("priority")

      expect(page).to have_no_text(mark)
      expect(page).to have_no_text(unmark)
    end
  end

  context "with a globally required custom field" do
    let(:custom_field) { create(:integer_wp_custom_field, name: "Impact", is_required: true) }
    let!(:variant) { variant_showing(custom_field) }

    before { visit edit_type_form_configuration_path(type_id: variant.type_id) }

    it "says so and disables the action, naming where the setting lives" do
      expect_badge(custom_field.attribute_name, text: globally_label, scheme: "attention")

      form.open_attribute_menu(custom_field.attribute_name)

      item = page.find_test_selector("type-form-configuration-toggle-required-#{custom_field.attribute_name}",
                                     visible: :all)

      expect(item).to have_text(mark)
      expect(item).to have_text(I18n.t("types.edit.form_configuration.required.globally_hint"))
      expect(item[:class]).to include("ActionListItem--disabled")
      expect(item).to have_css("[aria-disabled='true']", visible: :all)
      expect(item).to have_no_css("a", visible: :all)
    end
  end

  context "with a variant that borrows the form configuration", with_flag: { type_variants: true } do
    let!(:owner) { variant_showing(custom_field) }
    let!(:borrower) { create(:type_variant, type: owner.type) }

    before do
      owner.update!(required_attributes: [custom_field.attribute_name])
      link_configuration(borrower, source: owner, aspect: TypeVariant::FORM_CONFIGURATION)
      visit edit_type_form_configuration_path(type_id: borrower.type_id, variant_id: borrower.id)
    end

    it "shows the inherited state without a toggle" do
      expect(page).to have_text("Impact")
      expect_badge(custom_field.attribute_name, text: in_type_label, scheme: "severe")
      expect(page).to have_no_test_selector("type-form-configuration-attribute-actions-#{custom_field.attribute_name}")
    end
  end
end
