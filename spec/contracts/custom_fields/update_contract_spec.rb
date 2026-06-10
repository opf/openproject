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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"
require_relative "shared_contract_examples"

RSpec.describe CustomFields::UpdateContract do
  it_behaves_like "custom_field contract" do
    let(:custom_field) do
      build_stubbed(:custom_field,
                    name: custom_field_name,
                    type: custom_field_type,
                    field_format: custom_field_field_format,
                    editable: custom_field_editable,
                    is_filter: custom_field_is_filter,
                    is_for_all: custom_field_is_for_all,
                    is_required: custom_field_is_required,
                    max_length: custom_field_max_length,
                    min_length: custom_field_min_length,
                    possible_values: custom_field_possible_values,
                    regexp: custom_field_regexp,
                    formula: custom_field_formula,
                    searchable: custom_field_searchable,
                    admin_only: custom_field_admin_only,
                    default_value: custom_field_default_value,
                    multi_value: custom_field_multi_value,
                    content_right_to_left: custom_field_right_to_left,
                    custom_field_section_id: custom_field_custom_field_section_id,
                    allow_non_open_versions: custom_field_allow_non_open_versions)
    end

    subject(:contract) { described_class.new(custom_field, current_user) }

    context "for a calculated field", with_ee: %i[calculated_values] do
      let(:custom_field_field_format) { "calculated_value" }

      let(:custom_field_formula) { "1 + 1" }

      context "with a CustomFields::RecalculateValuesJob already existing",
              with_good_job: CustomFields::RecalculateValuesJob do
        before do
          CustomFields::RecalculateValuesJob
            .set(wait: 10.minutes) # GoodJob executes inline job without wait immediately
            .perform_later(user: current_user, custom_field_id: custom_field.id)
        end

        it_behaves_like "contract is invalid", base: :previous_custom_field_recalculation_unprocessed
      end
    end
  end
end
