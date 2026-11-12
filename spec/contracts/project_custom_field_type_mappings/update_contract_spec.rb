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
require "contracts/shared/model_contract_shared_context"

RSpec.describe ProjectCustomFieldTypeMappings::UpdateContract do
  include_context "ModelContract shared context"

  let(:user) { build_stubbed(:admin) }
  let(:type_variant) { build_stubbed(:type_variant) }
  let(:project_custom_field) { build_stubbed(:project_custom_field) }
  let(:mapping) { ProjectCustomFieldTypeMapping.new(type_variant:, project_custom_field:) }
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
        type_variant:,
        custom_field_id: work_package_custom_field.id
      )
    end

    it_behaves_like "contract is invalid", custom_field_id: :invalid
  end

  include_examples "contract reuses the model errors"
end
