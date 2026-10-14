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

module CustomFields
  # Which attributes the details form shows for a custom field.
  class DetailsFieldVisibility
    attr_reader :model

    def initialize(model)
      @model = model
    end

    def show_section_field?
      model.is_a?(ProjectCustomField) || model.is_a?(UserCustomField)
    end

    def show_default_bool_field?
      %w[bool].include?(model.field_format)
    end

    def show_default_text_field?
      %w[list bool date datetime text user version hierarchy weighted_item_list calculated_value].exclude?(model.field_format)
    end

    def show_default_rich_text_field?
      %w[text].include?(model.field_format)
    end

    def show_has_comment_field?
      model.can_have_comment?
    end

    def show_is_required_field?
      %w[calculated_value bool].exclude?(model.field_format)
    end

    def show_min_max_length_field?
      model.length_limits_possible?
    end

    def show_min_max_value_field?
      model.numeric_bounds_possible?
    end

    def show_regex_field?
      %w[list bool date datetime user version hierarchy weighted_item_list calculated_value].exclude?(model.field_format)
    end

    def show_right_to_left_field?
      model.is_a?(WorkPackageCustomField) && %w[text].include?(model.field_format)
    end

    def show_multi_value_field?
      model.multi_value_possible?
    end

    def show_formula_field?
      %w[calculated_value].include?(model.field_format)
    end

    def show_is_for_all_field?
      model.is_a?(ProjectCustomField)
    end

    def show_is_filter_field?
      model.is_a?(WorkPackageCustomField)
    end

    def show_is_searchable_field?
      (model.is_a?(WorkPackageCustomField) || model.is_a?(ProjectCustomField)) &&
        %w[bool date datetime float int user version hierarchy weighted_item_list calculated_value].exclude?(model.field_format)
    end

    def show_non_open_versions_field?
      %w[version].include?(model.field_format) && model.allow_non_open_versions_possible?
    end

    def show_admin_only_field?
      model.class.customized_class&.admin_only_custom_fields_allowed?
    end

    def show_editable_field?
      model.is_a?(UserCustomField)
    end

    def show_on_user_card_field?
      model.is_a?(UserCustomField)
    end
  end
end
