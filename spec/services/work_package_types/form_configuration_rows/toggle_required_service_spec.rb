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
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

module WorkPackageTypes
  module FormConfigurationRows
    RSpec.describe ToggleRequiredService, type: :service do
      let(:user) { create(:admin) }
      let(:custom_field) { create(:integer_wp_custom_field) }
      let(:type) { create(:type) }
      let(:variant) do
        type.default_variant.tap do |base|
          base.attribute_groups = [["details", [custom_field.attribute_name, "priority"]]]
          base.custom_field_ids = [custom_field.id]
          base.save!
        end
      end

      def toggle(row_key)
        described_class.new(user:, variant:, row_key:).call
      end

      it "marks a custom field required for this variant" do
        expect(toggle(custom_field.attribute_name)).to be_success
        expect(variant.reload.required_attributes).to contain_exactly(custom_field.attribute_name)
      end

      it "marks it optional again" do
        toggle(custom_field.attribute_name)

        expect(toggle(custom_field.attribute_name)).to be_success
        expect(variant.reload.required_attributes).to eq([])
      end

      it "leaves other variants of the same type alone" do
        sibling = create(:type_variant, type:)
        toggle(custom_field.attribute_name)

        expect(sibling.reload[:required_attributes]).to eq([])
      end

      it "rejects a row that is not on the form" do
        other_field = create(:integer_wp_custom_field)

        result = toggle(other_field.attribute_name)

        expect(result).to be_failure
        expect(result.errors.full_messages)
          .to include(a_string_including(I18n.t("types.edit.form_configuration.not_found")))
      end

      it "rejects a built-in attribute" do
        result = toggle("priority")

        expect(result).to be_failure
        expect(result.errors.full_messages)
          .to include(a_string_including(I18n.t("types.edit.form_configuration.required.not_a_custom_field")))
        expect(variant.reload.required_attributes).to eq([])
      end

      it "rejects a custom field that is already required everywhere" do
        custom_field.update!(is_required: true)

        result = toggle(custom_field.attribute_name)

        expect(result).to be_failure
        expect(result.errors.full_messages)
          .to include(a_string_including(I18n.t("types.edit.form_configuration.required.already_required_globally")))
        expect(variant.reload.required_attributes).to eq([])
      end

      it "rejects a variant that borrows its form configuration" do
        borrower = create(:type_variant, type: create(:type))
        link_configuration(borrower, source: variant, aspect: TypeVariant::FORM_CONFIGURATION)

        result = described_class.new(user:, variant: borrower, row_key: custom_field.attribute_name).call

        expect(result).to be_failure
        expect(result.errors.full_messages)
          .to include(a_string_including(I18n.t("types.edit.form_configuration.required.not_available_when_linked")))
        expect(borrower.reload[:required_attributes]).to eq([])
      end
    end
  end
end
