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
  module FormConfigurationRows
    class ToggleRequiredService < ::BaseServices::BaseCallable
      include ::WorkPackageTypes::FormConfiguration::Concern

      def initialize(user:, variant:, row_key:)
        super(user:, variant:)
        @row_key = row_key.to_s.strip
      end

      def perform
        row = find_row(@row_key)
        return failure_with_message(I18n.t("types.edit.form_configuration.not_found")) unless row

        error = rejection_reason
        return failure_with_message(error) if error

        toggle
      end

      private

      def rejection_reason
        if variant.linked?(TypeVariant::FORM_CONFIGURATION)
          I18n.t("types.edit.form_configuration.required.not_available_when_linked")
        elsif custom_field.nil?
          I18n.t("types.edit.form_configuration.required.not_a_custom_field")
        elsif custom_field.is_required?
          I18n.t("types.edit.form_configuration.required.already_required_globally")
        end
      end

      def custom_field
        return @custom_field if defined?(@custom_field)

        @custom_field = if CustomField.custom_field_attribute?(@row_key)
                          WorkPackageCustomField.find_by(id: @row_key.delete_prefix("custom_field_").to_i)
                        end
      end

      def toggle
        OpenProject::Mutex.with_advisory_lock_transaction(variant, "required_attributes") do
          variant.reload
          variant.update!(required_attributes: next_required_attributes)
        end

        ServiceResult.success(result: variant)
      rescue ActiveRecord::RecordInvalid
        ServiceResult.failure(result: variant, errors: variant.errors)
      end

      def next_required_attributes
        current = variant[:required_attributes].map(&:to_s)

        current.include?(@row_key) ? current - [@row_key] : current | [@row_key]
      end
    end
  end
end
