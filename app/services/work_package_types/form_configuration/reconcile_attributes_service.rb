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
    # Each reference kind is inserted against its own partial unique index: PostgreSQL refuses a
    # targetless ON CONFLICT while the table carries a deferrable unique constraint (the position
    # constraint), so the arbiter has to be named. A custom field deleted between the existence
    # check and the insert fails the foreign key; the savepoint is rolled back and the insert runs
    # once more without it.
    class ReconcileAttributesService
      KEY_INDEX = :index_form_configuration_attributes_on_owner_and_key
      CUSTOM_FIELD_INDEX = :index_form_configuration_attributes_on_owner_and_custom_field

      def initialize(variant)
        @owner = variant.owner_of(TypeVariant::FORM_CONFIGURATION)
      end

      def call
        rows = missing_rows
        insert(rows) if rows.any?

        ServiceResult.success(result: owner)
      end

      private

      attr_reader :owner

      def insert(rows, retried: false)
        by_key, by_custom_field = rows.partition { |row| row[:custom_field_id].nil? }

        FormConfigurationAttribute.transaction(requires_new: true) do
          FormConfigurationAttribute.insert_all(by_key, unique_by: KEY_INDEX) if by_key.any?
          FormConfigurationAttribute.insert_all(by_custom_field, unique_by: CUSTOM_FIELD_INDEX) if by_custom_field.any?
        end
      rescue ActiveRecord::InvalidForeignKey
        raise if retried

        insert(without_deleted_custom_fields(rows), retried: true)
      end

      def missing_rows
        present_custom_field_ids, present_keys = present_references

        rows = owner.work_package_attributes.keys.filter_map do |key|
          reference = FormConfigurationAttribute.reference_for(key)
          next if reference_present?(reference, key, present_custom_field_ids, present_keys)

          reference.merge(type_variant_id: owner.id)
        end

        without_deleted_custom_fields(rows)
      end

      def reference_present?(reference, key, present_custom_field_ids, present_keys)
        if reference[:custom_field_id]
          present_custom_field_ids.include?(reference[:custom_field_id])
        else
          present_keys.include?(key)
        end
      end

      def present_references
        pairs = owner.form_attributes.pluck(:custom_field_id, :attribute_key)

        [pairs.filter_map(&:first).to_set, pairs.filter_map(&:last).to_set]
      end

      def without_deleted_custom_fields(rows)
        ids = rows.filter_map { |row| row[:custom_field_id] }
        return rows if ids.empty?

        existing = WorkPackageCustomField.where(id: ids).pluck(:id).to_set
        rows.select { |row| row[:custom_field_id].nil? || existing.include?(row[:custom_field_id]) }
      end
    end
  end
end
