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

RSpec.describe ProjectCustomFieldTypeMappings::ToggleService do
  let(:type) { create(:type) }
  let(:project_custom_field) { create(:project_custom_field) }
  let(:instance) { described_class.new(user:) }

  let(:params) do
    {
      type_id: type.id,
      custom_field_id: project_custom_field.id
    }
  end

  context "with admin permissions" do
    let(:user) { create(:admin) }

    it "toggles a project custom field for the type" do
      expect(type.project_custom_fields).to be_empty

      2.times do
        expect(instance.call(**params, value: "1")).to be_success

        expect(type.reload.project_custom_fields).to contain_exactly(project_custom_field)
      end

      2.times do
        expect(instance.call(**params, value: "0")).to be_success

        expect(type.reload.project_custom_fields).to be_empty
      end
    end

    it "does not map a work package custom field to the type" do
      work_package_custom_field = create(:wp_custom_field)

      result = instance.call(
        type_id: type.id,
        custom_field_id: work_package_custom_field.id,
        value: "1"
      )

      expect(result).to be_failure
      expect(ProjectCustomFieldTypeMapping).not_to exist(
        type_id: type.id,
        custom_field_id: work_package_custom_field.id
      )
    end
  end

  context "without admin permissions" do
    let(:user) { create(:user) }

    it "does not toggle project custom fields for the type" do
      expect(instance.call(**params, value: "1")).to be_failure

      expect(type.reload.project_custom_fields).to be_empty
    end
  end
end
