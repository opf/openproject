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
  module FormConfiguration
    class EnsureAttributeMembershipService
      KEY_INDEX = :index_form_configuration_attributes_on_owner_and_key
      CUSTOM_FIELD_INDEX = :index_form_configuration_attributes_on_owner_and_custom_field

      def initialize(form)
        @form = form
      end

      def call
        insert_missing
        ServiceResult.success(result: form)
      end

      private

      attr_reader :form

      def insert_missing
        rows = missing_rows
        return if rows.empty?

        insert_in_savepoint(rows)
      rescue ActiveRecord::InvalidForeignKey
        insert_in_savepoint(without_deleted_custom_fields(rows))
      end

      def missing_rows
        known = stored_references
        rows = catalog_rows.reject { stored?(it, known) }

        without_deleted_custom_fields(rows)
      end

      def catalog_rows
        form.work_package_attributes.keys.map { row_for(it) }
      end

      def row_for(key)
        FormConfigurationAttribute.reference_for(key).merge(form_configuration_id: form.id)
      end

      def stored?(row, known)
        if row[:custom_field_id]
          known[:custom_field_ids].include?(row[:custom_field_id])
        else
          known[:attribute_keys].include?(row[:attribute_key])
        end
      end

      def stored_references
        pairs = form.form_attributes.pluck(:custom_field_id, :attribute_key)

        {
          custom_field_ids: pairs.filter_map(&:first).to_set,
          attribute_keys: pairs.filter_map(&:last).to_set
        }
      end

      def without_deleted_custom_fields(rows)
        ids = rows.filter_map { it[:custom_field_id] }
        return rows if ids.empty?

        live_ids = WorkPackageCustomField.where(id: ids).pluck(:id).to_set
        rows.select { it[:custom_field_id].nil? || live_ids.include?(it[:custom_field_id]) }
      end

      # Each reference kind is unique under its own partial index, so ON CONFLICT
      # can name only one of them per INSERT. InvalidForeignKey aborts the
      # surrounding transaction; the savepoint leaves it usable for one retry.
      def insert_in_savepoint(rows)
        attribute_rows, custom_field_rows = rows.partition { it[:custom_field_id].nil? }

        FormConfigurationAttribute.transaction(requires_new: true) do
          insert_ignoring_conflicts(attribute_rows, KEY_INDEX)
          insert_ignoring_conflicts(custom_field_rows, CUSTOM_FIELD_INDEX)
        end
      end

      def insert_ignoring_conflicts(rows, conflict_target)
        return if rows.empty?

        FormConfigurationAttribute.insert_all(rows, unique_by: conflict_target)
      end
    end
  end
end
