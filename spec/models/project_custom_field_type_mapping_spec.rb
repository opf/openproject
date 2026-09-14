# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe ProjectCustomFieldTypeMapping do
  describe "uniqueness by type variant" do
    let(:variant) { create(:type).default_variant }
    let(:project_custom_field) { create(:project_custom_field) }

    it "maps a project custom field to a type variant only once" do
      variant.project_custom_fields << project_custom_field

      expect(described_class).to exist(custom_field_id: project_custom_field.id,
                                       type_variant_id: variant.id)

      expect do
        variant.project_custom_fields << project_custom_field
      end.to raise_error(ActiveRecord::RecordInvalid, /Custom field has already been taken/)
    end
  end
end
