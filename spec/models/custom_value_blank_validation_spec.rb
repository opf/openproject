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

RSpec.describe CustomValue, "requiring a field value" do
  def blank_error_on(custom_field, customized: nil)
    value = described_class.new(custom_field:, customized:, value: "")
    value.valid?
    value.errors[:value]
  end

  describe "a customizable without its own required rule" do
    let(:custom_field) { create(:project_custom_field, field_format: "string", is_required: true) }
    let(:project) { create(:project) }

    it "still refuses a blank value for a required field" do
      expect(blank_error_on(custom_field, customized: project)).to be_present
    end

    it "accepts a blank value for an optional field" do
      custom_field.update!(is_required: false)

      expect(blank_error_on(custom_field, customized: project)).to be_empty
    end
  end

  describe "a value with no customized present" do
    it "falls back to the field's own flag" do
      custom_field = create(:custom_field, field_format: "string", is_required: true)

      expect(blank_error_on(custom_field)).to be_present
    end

    it "lets a required field be created with a blank default" do
      field = build(:work_package_custom_field, field_format: "string", is_required: true,
                                                default_value: nil)

      expect(field.save).to be(true)
    end
  end

  describe "a work package" do
    shared_let(:status) { create(:status, is_default: true) }
    shared_let(:priority) { create(:priority, is_default: true) }

    let(:custom_field) { create(:integer_wp_custom_field, is_for_all: true) }
    let(:type) { create(:type) }
    let(:project) { create(:project, types: [type], work_package_custom_fields: [custom_field]) }
    let(:work_package) { build(:work_package, project:, type:, status:, priority:) }

    def require_on_the_variant
      variant = type.default_variant
      variant.attribute_groups = [["Details", [custom_field.attribute_name]]]
      variant.custom_field_ids = [custom_field.id]
      variant.required_attributes = [custom_field.attribute_name]
      variant.save!
    end

    it "refuses a blank value when a variant requires it, but custom field does not", :aggregate_failures do
      require_on_the_variant

      expect(custom_field).not_to be_required
      expect(blank_error_on(custom_field, customized: work_package)).to be_present
    end

    it "accepts a blank value when neither the field nor the variant demands one" do
      expect(blank_error_on(custom_field, customized: work_package)).to be_empty
    end
  end
end
