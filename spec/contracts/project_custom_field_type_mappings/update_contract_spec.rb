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
require "contracts/shared/model_contract_shared_context"

RSpec.describe ProjectCustomFieldTypeMappings::UpdateContract do
  include_context "ModelContract shared context"

  let(:user) { build_stubbed(:admin) }
  let(:type) { build_stubbed(:type) }
  let(:project_custom_field) { build_stubbed(:project_custom_field) }
  let(:mapping) { ProjectCustomFieldTypeMapping.new(type:, project_custom_field:) }
  let(:contract) { described_class.new(mapping, user) }

  it_behaves_like "contract is valid"

  context "with a non-admin user" do
    let(:user) { build_stubbed(:user) }

    it_behaves_like "contract is invalid", base: :error_unauthorized
  end

  context "with a work package custom field" do
    let(:work_package_custom_field) { create(:wp_custom_field) }
    let(:mapping) do
      ProjectCustomFieldTypeMapping.new(
        type:,
        custom_field_id: work_package_custom_field.id
      )
    end

    it_behaves_like "contract is invalid", custom_field_id: :invalid
  end

  include_examples "contract reuses the model errors"
end
