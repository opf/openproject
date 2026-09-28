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
      attr_reader :form, :variant

      def self.for_variant(variant) = new(form: variant.form_configuration, variant:)

      def initialize(form:, variant: nil)
        @form = form
        @variant = variant
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

      def reset_dialog_path = routes.reset_dialog_form_configuration_path(form)

      def reset_path = routes.reset_form_configuration_path(form)

      def group_path(action = nil, **)
        routes.public_send([action, "form_configuration_group_path"].compact.join("_"), form, **)
      end

      def row_path(action = nil, **)
        routes.public_send([action, "form_configuration_row_path"].compact.join("_"), form, **)
      end

      def toggle_required_path(row_key)
        routes.toggle_required_type_form_configuration_row_path(**variant.path_args, row_key:)
      end

      private

      def owner = variant || form

      def routes = Rails.application.routes.url_helpers
    end
  end
end
