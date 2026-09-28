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

class TypeVariant
  module FormReference
    extend ActiveSupport::Concern

    included do
      belongs_to :form_configuration, autosave: true, inverse_of: :type_variants
    end

    class_methods do
      def form_configuration_join(variant_id_expr)
        join = "LEFT JOIN type_variants variant_form ON variant_form.id = #{variant_id_expr}"

        [join, "variant_form.form_configuration_id", "variant_form.form_configuration_excluded_elements"]
      end
    end

    def attribute_groups
      return form_attribute_groups if attribute_groups_changed?

      without_excluded_elements(form_attribute_groups)
    end

    def required_attributes
      super & attribute_group_members
    end

    def custom_fields
      return WorkPackageCustomField.none if form_configuration.nil?

      fields = form_configuration.custom_fields
      excluded_ids = excluded_custom_field_ids(TypeVariant::FORM_CONFIGURATION)
      return fields if excluded_ids.empty?

      fields.where.not(id: excluded_ids)
    end

    def custom_fields=(fields)
      form_configuration.custom_fields = fields
    end

    def custom_field_ids
      Array(form_configuration&.custom_field_ids) - excluded_custom_field_ids(TypeVariant::FORM_CONFIGURATION)
    end

    def custom_field_ids=(ids)
      form_configuration.custom_field_ids = ids
    end

    def type_form_configuration
      type.default_variant.form_configuration unless is_default_variant?
    end

    private

    def without_excluded_elements(groups)
      excluded = excluded_elements(TypeVariant::FORM_CONFIGURATION)
      return groups if excluded.empty?

      groups.filter_map do |group|
        next retained_query_group(group, excluded) if group.group_type == :query

        remaining = group.attributes - excluded
        next if remaining.empty?
        next group if remaining.length == group.attributes.length

        group.dup.tap { |narrowed| narrowed.attributes = remaining }
      end
    end

    # A query group is a section holding a single query, stored under the element key "query_<id>"
    # (see Type::AttributeGroups#to_attribute_group_array), so excluding that key drops the whole
    # group. It cannot go through the narrowing above because Type::QueryGroup#attributes is the
    # query itself rather than a list of attribute keys.
    #
    # A group whose query no longer exists is left alone: there is no id to exclude it by, and
    # dropping it here would hide it from the form configuration that still has to repair it.
    def retained_query_group(group, excluded)
      return group if group.query.blank?

      group unless excluded.include?(group.query_attribute_name.to_s)
    end
  end
end
