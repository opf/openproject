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

module WorkPackageTypes
  module CopyConfiguration
    # One-time copy of a source variant's form configuration onto another variant
    # ("Copy from variant" on the form configuration tab).
    #
    # Embedded query groups are rebuilt as fresh Query records so the two types
    # never share queries. Saving replaces the previous configuration: the
    # variant's old embedded queries are destroyed by the attribute-groups cleanup
    # on save, and its active custom fields are re-derived from the copied
    # groups.
    class FormConfigurationService < BaseService
      def call(source:)
        return invalid_source_result unless valid_source?(source)

        groups_result = duplicated_groups(source)
        return groups_result if groups_result.failure?

        persist(groups_result.result)
      end

      private

      def aspect = TypeVariant::FORM_CONFIGURATION

      def duplicated_groups(source)
        groups = presenting_type(source).attribute_groups.map do |group|
          case group
          when Type::QueryGroup
            query_result = FormConfiguration::EmbeddedQueryBuilder.rebuild(query: group.query, user:)
            return query_result if query_result.failure?

            group_entry(group, [query_result.result])
          else
            group_entry(group, group.attributes.dup)
          end
        end

        ServiceResult.success(result: groups)
      end

      # The variant whose *presented* configuration is copied. Reading a presentation rather than
      # the owner's raw groups is what makes exclusions survive the copy: a link in between may
      # exclude elements, and going Independent has to freeze what the variant was showing instead
      # of restoring what it was hiding. Excluded query groups are dropped before this runs, so
      # they are never rebuilt as fresh queries either.
      #
      # When the variant inherits from `source`, its own link's exclusions apply on top of the
      # chain's, so the variant is the one presenting. When copying from an unrelated variant on the
      # form configuration tab, that variant's presentation is what the user picked — and it
      # resolves through its own links already.
      def presenting_type(source)
        variant.source_for(aspect) == source ? variant : source
      end

      def group_entry(group, members)
        entry = [group.key, members]
        entry << group.display_name if group.display_name.present?
        entry
      end

      def persist(groups)
        Type.transaction do
          variant.attribute_groups = groups
          sync_active_custom_fields
          variant.save!
        end

        ServiceResult.success(result: variant)
      rescue ActiveRecord::RecordInvalid
        ServiceResult.failure(result: variant, errors: variant.errors)
      end

      # Same syncing as WorkPackageTypes::UpdateService: the active custom
      # fields follow from the custom fields placed in the groups.
      def sync_active_custom_fields
        # The groups just copied onto this variant, not whatever a project would resolve it to.
        variant.custom_field_ids = variant.attribute_groups
                                    .flat_map(&:members)
                                    .filter_map do |attribute|
                                      if CustomField.custom_field_attribute?(attribute)
                                        attribute.delete_prefix("custom_field_").to_i
                                      end
                                    end.uniq
      end
    end
  end
end
