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
    class GenerateDefaultsService
      def initialize(variant)
        @variant = variant
      end

      def call
        blocker = blocking_failure
        return blocker if blocker

        generate_defaults

        ServiceResult.success(result: variant)
      end

      private

      attr_reader :variant

      def blocking_failure
        return failure(:linked) if variant.linked?(TypeVariant::FORM_CONFIGURATION)

        failure(:already_configured) if variant.form_groups.exists? || variant.form_attributes.exists?
      end

      def generate_defaults
        TypeVariant.transaction do
          variant.default_attribute_groups.each { |key, members| create_group(key, members) }
          ReconcileAttributesService.new(variant).call
        end
      end

      def create_group(default_key, members)
        group = variant.form_groups.create!(kind: FormConfigurationGroup::ATTRIBUTE, default_key: default_key.to_s)

        members.each_with_index do |key, index|
          variant.form_attributes.create!(group:, position: index + 1, **FormConfigurationAttribute.reference_for(key))
        end
      end

      def failure(reason)
        variant.errors.add(:base, I18n.t("types.edit.form_configuration.defaults_not_generated.#{reason}"))

        ServiceResult.failure(result: variant, errors: variant.errors)
      end
    end
  end
end
