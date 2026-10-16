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

# Reuse of a variant's configuration aspects from its type's base variant. `linked_aspects` names
# the aspects a variant inherits from the base, the rest are independent and owned by the variant.
# A linked excludable aspect may drop elements it inherits via `<aspect>_excluded_elements`.
class TypeVariant
  module ConfigurationLinkable
    extend ActiveSupport::Concern

    # Custom fields appear in an aspect's element list under CustomField#attribute_name.
    # Mirrors the prefix that method builds.
    CUSTOM_FIELD_ELEMENT_PREFIX = "custom_field_"

    prepended do
      validate :linked_aspects_are_valid
    end

    class_methods do
      # Builds SQL to resolve, per row, the variant that owns `aspect`'s configuration: the type's
      # base when the row's variant inherits the aspect, the variant itself when it owns it.
      def effective_configuration_join(variant_id_expr, aspect)
        aspect = validated_configuration_aspect(aspect)
        variant = "variant_#{aspect}"
        base = "base_#{aspect}"
        inherited = "'#{aspect}' = ANY(#{variant}.linked_aspects)"
        excluded = TypeVariant::EXCLUDABLE_ASPECTS.include?(aspect) ? "#{variant}.#{aspect}_excluded_elements" : "'{}'::text[]"

        join = <<~SQL.squish
          LEFT JOIN type_variants #{variant} ON #{variant}.id = #{variant_id_expr}
          LEFT JOIN type_variants #{base} ON #{base}.type_id = #{variant}.type_id AND #{base}.is_default_variant
        SQL

        [join,
         "CASE WHEN #{inherited} THEN #{base}.id ELSE #{variant_id_expr} END",
         "CASE WHEN #{inherited} THEN #{excluded} ELSE '{}'::text[] END"]
      end

      # Condition keeping only custom fields `aspect` does not exclude. Custom fields are excluded
      # under CustomField#attribute_name, so the id is keyed back into that form rather than compared
      # numerically. `<> ALL` over the empty array is TRUE, so callers never branch on "excludes nothing".
      def excluded_custom_field_condition(custom_field_id_expr, excluded_expr)
        "('#{CUSTOM_FIELD_ELEMENT_PREFIX}' || #{custom_field_id_expr}) <> ALL (#{excluded_expr})"
      end

      # An aspect names columns, so it reaches SQL as an identifier rather than a bind. Every
      # interpolation goes through here, and an unknown aspect raises rather than being spliced in.
      def validated_excludable_aspect(aspect)
        candidate = aspect.to_s
        unless TypeVariant::EXCLUDABLE_ASPECTS.include?(candidate)
          raise ArgumentError, "Configuration aspect #{aspect.inspect} has no exclusions"
        end

        candidate
      end

      def validated_configuration_aspect(aspect)
        aspect.to_s.tap do |candidate|
          raise ArgumentError, "Unknown configuration aspect #{aspect.inspect}" unless TypeVariant::ASPECTS.include?(candidate)
        end
      end
    end

    def linked?(aspect)
      linked_aspects.include?(self.class.validated_configuration_aspect(aspect))
    end

    def source_for(aspect)
      type.default_variant if linked?(aspect)
    end

    def link!(aspect)
      aspect = self.class.validated_configuration_aspect(aspect)
      return if linked_aspects.include?(aspect)

      update!(linked_aspects: linked_aspects + [aspect])
    end

    def unlink!(aspect)
      aspect = self.class.validated_configuration_aspect(aspect)
      attributes = { linked_aspects: linked_aspects - [aspect] }
      attributes["#{aspect}_excluded_elements"] = [] if TypeVariant::EXCLUDABLE_ASPECTS.include?(aspect)

      update!(attributes)
    end

    def owner_of(aspect)
      source_for(aspect) || self
    end

    def excludable?(aspect)
      return false unless TypeVariant::EXCLUDABLE_ASPECTS.include?(aspect)

      aspect == TypeVariant::FORM_CONFIGURATION || linked?(aspect)
    end

    def excluded_elements(aspect)
      return [] unless excludable?(aspect)

      Array(self["#{aspect}_excluded_elements"]).uniq
    end

    # Readers of inherited aspects resolve through the source, so a plain `variant.patterns` is
    # always the configuration in force. Resolving in the reader rather than behind a separate
    # opt-in method is deliberate: a caller can't silently read its own value by forgetting to opt
    # in - a slip an owning variant would mask, since it reads the same either way.
    #
    # Writers stay untouched: assigning always writes this variant's own row.
    def patterns
      source = source_for(TypeVariant::DEFAULTS)
      return super if source.nil?

      source.patterns
    end

    def default_work_package_description
      source = source_for(TypeVariant::DEFAULTS)
      return super if source.nil?

      source.default_work_package_description
    end

    def artefact_export_mode
      source = source_for(TypeVariant::PDF_EXPORT)
      return super if source.nil?

      source.artefact_export_mode
    end

    # Resolved here rather than on #pdf_export_templates so that the object handed out always wraps
    # the receiving variant: it is a mutator as much as a reader, and returning the source's would
    # let an inheriting variant write the source's config.
    def export_templates_disabled
      source = source_for(TypeVariant::PDF_EXPORT)
      return super if source.nil?

      source.export_templates_disabled
    end

    def export_templates_order
      source = source_for(TypeVariant::PDF_EXPORT)
      return super if source.nil?

      source.export_templates_order
    end

    def export_templates_settings
      source = source_for(TypeVariant::PDF_EXPORT)
      return super if source.nil?

      source.export_templates_settings
    end

    # The ids of the custom fields this variant does not inherit for `aspect`. An element list can
    # also carry plain attribute keys ("assignee") and query groups ("query_7"), which have no
    # custom field to map to and are dropped here.
    def excluded_custom_field_ids(aspect)
      custom_field_ids_among(excluded_elements(aspect))
    end

    def required_custom_field_ids
      custom_field_ids_among(required_attributes)
    end

    private

    def custom_field_ids_among(elements)
      elements.filter_map do |element|
        next unless CustomField.custom_field_attribute?(element)

        element.delete_prefix(CUSTOM_FIELD_ELEMENT_PREFIX).to_i
      end
    end

    def linked_aspects_are_valid
      errors.add(:linked_aspects, :inclusion) if (linked_aspects - TypeVariant::ASPECTS).any?
      errors.add(:linked_aspects, :present) if is_default_variant? && linked_aspects.any?
    end
  end
end
