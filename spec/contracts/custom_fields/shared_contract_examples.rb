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

RSpec.shared_examples_for "custom_field contract" do
  include_context "ModelContract shared context"

  current_user { build_stubbed(:admin) }

  let(:custom_field_name) { "Project name" }
  let(:custom_field_type) { "ProjectCustomField" }
  let(:custom_field_editable) { true }
  let(:custom_field_field_format) { "int" }
  let(:custom_field_is_filter) { true }
  let(:custom_field_is_for_all) { true }
  let(:custom_field_is_required) { true }
  let(:custom_field_max_length) { 0 }
  let(:custom_field_min_length) { 0 }
  let(:custom_field_max_value) { nil }
  let(:custom_field_min_value) { nil }
  let(:custom_field_possible_values) { [] }
  let(:custom_field_regexp) { nil }
  let(:custom_field_formula) { nil }
  let(:custom_field_searchable) { true }
  let(:custom_field_admin_only) { true }
  let(:custom_field_default_value) { nil }
  let(:custom_field_multi_value) { false }
  let(:custom_field_right_to_left) { false }
  let(:custom_field_custom_field_section_id) { custom_field_section.id }
  let(:custom_field_allow_non_open_versions) { nil }
  let(:custom_field_project_specific_value_restriction) { nil }

  let(:custom_field_section) { build_stubbed(:project_custom_field_section) }

  it_behaves_like "contract is valid for active admins and invalid for regular users"

  context "if the name is nil" do
    let(:custom_field_name) { nil }

    it_behaves_like "contract is invalid", name: %i(blank)
  end

  context "for a boolean field" do
    let(:custom_field_field_format) { "bool" }
    let(:custom_field_is_required) { false }

    context "if required is true" do
      let(:custom_field_is_required) { true }

      it_behaves_like "contract is invalid", is_required: :cannot_be_true
    end
  end

  context "for a calculated field", with_ee: %i[calculated_values] do
    let(:custom_field_field_format) { "calculated_value" }
    let(:custom_field_is_required) { false }
    let(:custom_field_formula) { "1 + 1" }

    context "without calculated_values enterprise feature", with_ee: %i[] do
      it_behaves_like "contract is invalid", base: :error_enterprise_only
    end

    context "with calculated_values enterprise feature" do
      it_behaves_like "contract is valid"
    end

    context "if required is true" do
      let(:custom_field_is_required) { true }

      it_behaves_like "contract is invalid", is_required: :cannot_be_true
    end
  end

  context "with project-specific value restrictions" do
    let(:custom_field_type) { "WorkPackageCustomField" }
    let(:custom_field_field_format) { "list" }
    let(:custom_field_possible_values) { %w[A B] }
    let(:custom_field_project_specific_value_restriction) { "allow" }

    context "for a list field", with_ee: %i[project_specific_list_values] do
      it_behaves_like "contract is valid"
    end

    context "for a hierarchy field", with_ee: %i[custom_field_hierarchies project_specific_list_values] do
      let(:custom_field_field_format) { "hierarchy" }
      let(:custom_field_possible_values) { [] }

      it_behaves_like "contract is valid"
    end

    context "for a weighted item list field", with_ee: %i[weighted_item_lists project_specific_list_values] do
      let(:custom_field_field_format) { "weighted_item_list" }
      let(:custom_field_possible_values) { [] }

      it_behaves_like "contract is valid"
    end

    context "when enabling them while the enterprise plan does not include project-specific values" do
      let(:custom_field_project_specific_value_restriction) { nil }

      before do
        custom_field.project_specific_value_restriction = "allow"
      end

      it_behaves_like "contract is invalid", project_specific_value_restriction: :error_enterprise_only
    end

    # TODO: Remove this context once block mode is supported.
    context "when blocking values" do
      let(:custom_field_project_specific_value_restriction) { "block" }

      it_behaves_like "contract is invalid", project_specific_value_restriction: :inclusion
    end

    context "for a format without selectable values" do
      let(:custom_field_field_format) { "int" }
      let(:custom_field_possible_values) { [] }

      it_behaves_like "contract is invalid", project_specific_value_restriction: :not_supported
    end

    context "for a custom field that is not a work package custom field" do
      let(:custom_field_type) { "ProjectCustomField" }

      it_behaves_like "contract is invalid", project_specific_value_restriction: :not_supported
    end
  end
end
