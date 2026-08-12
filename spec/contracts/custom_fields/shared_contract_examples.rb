# frozen_string_literal: true

# -- copyright
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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
# ++

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
end
