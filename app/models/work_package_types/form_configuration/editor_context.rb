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
    class EditorContext
      include WorkPackageTypes::VariantRoutes

      attr_reader :form_configuration, :variant, :scope_project

      def self.for_variant(variant, scope_project:)
        new(form_configuration: variant.form_configuration, variant:, scope_project:)
      end

      def initialize(form_configuration:, variant: nil, scope_project: nil)
        @form_configuration = form_configuration
        @variant = variant
        @scope_project = scope_project
      end

      def readonly? = variant.present?

      def toggles_required? = variant.present?

      def exclusions
        return @exclusions if defined?(@exclusions)

        @exclusions = (ExclusionState.for(variant, TypeVariant::FORM_CONFIGURATION) if variant)
      end

      delegate :work_package_attributes, to: :owner

      def attribute_groups = owner.form_attribute_groups

      def required_attributes = variant&.required_attributes || []

      def reset_dialog_path = routes.reset_dialog_form_configuration_path(form_configuration)

      def reset_path = routes.reset_form_configuration_path(form_configuration)

      def group_path(action = nil, **)
        routes.public_send([action, "form_configuration_group_path"].compact.join("_"), form_configuration, **)
      end

      def row_path(action = nil, **)
        routes.public_send([action, "form_configuration_row_path"].compact.join("_"), form_configuration, **)
      end

      def toggle_required_path(row_key)
        toggle_required_variant_form_configuration_row_path(scope_project, variant, row_key)
      end

      private

      def owner = variant || form_configuration

      def routes = Rails.application.routes.url_helpers
    end
  end
end
