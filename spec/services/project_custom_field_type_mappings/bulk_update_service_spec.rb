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

RSpec.describe ProjectCustomFieldTypeMappings::BulkUpdateService do
  let(:type) { create(:type) }
  let(:project_custom_field_section) { create(:project_custom_field_section) }
  let(:other_section) { create(:project_custom_field_section) }

  let!(:project_custom_field) do
    create(:project_custom_field,
           name: "First field",
           project_custom_field_section:)
  end

  let!(:other_project_custom_field) do
    create(:project_custom_field,
           name: "Other field",
           project_custom_field_section: other_section)
  end

  let(:instance) { described_class.new(user:, type:, project_custom_field_section:) }

  context "with admin permissions" do
    let(:user) { create(:admin) }

    it "bulk enables and disables all project attributes of the section" do
      expect(instance.call(action: :enable)).to be_success

      expect(type.reload.project_custom_fields).to contain_exactly(project_custom_field)

      type.project_custom_fields << other_project_custom_field

      expect(instance.call(action: :disable)).to be_success

      expect(type.reload.project_custom_fields).to contain_exactly(other_project_custom_field)
    end

    it "fails for an unsupported action" do
      result = instance.call(action: :unsupported)

      expect(result).to be_failure
      expect(result.errors).to eq("Unsupported bulk update action: unsupported")
      expect(type.reload.project_custom_fields).to be_empty
    end
  end

  context "without admin permissions" do
    let(:user) { create(:user) }

    it "does not bulk enable project attributes" do
      expect(instance.call(action: :enable)).to be_failure

      expect(type.reload.project_custom_fields).to be_empty
    end
  end
end
