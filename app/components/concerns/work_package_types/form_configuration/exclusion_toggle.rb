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
    # Reusable module for rendering exclusion toggles for attributes and query group components
    module ExclusionToggle
      ASPECT = Type::ConfigurationLink::FORM_CONFIGURATION

      def render_exclusion_toggle?
        @exclusions.present? && exclusion_element_key.present?
      end

      private

      def exclusion_element_key
        raise SubclassResponsibilityError
      end

      def exclusion_toggle_label
        raise SubclassResponsibilityError
      end

      def excluded?
        @exclusions.excluded?(exclusion_element_key)
      end

      # A type cannot narrow an ancestor's link, so such a switch has nothing to write and is
      # rendered disabled.
      def inherited_exclusion?
        @exclusions.inherited?(exclusion_element_key)
      end

      def exclusion_toggle_path
        type_excluded_element_toggle_path(
          type_id: @exclusions.type.id,
          aspect: ASPECT,
          element: exclusion_element_key
        )
      end

      def exclusion_on_label
        t("types.edit.form_configuration.exclusions.inherited")
      end

      def exclusion_off_label
        t("types.edit.form_configuration.exclusions.excluded")
      end

      # As we can chain linked form configurations, the reason why this field is disables
      # may be anywhere in the linked chain. But it is useful to find out where it comes from.
      def exclusion_description
        return nil unless inherited_exclusion?

        t("types.edit.form_configuration.exclusions.excluded_in_source", source: @exclusions.source_name)
      end

      def exclusion_toggle_arguments
        {
          src: inherited_exclusion? ? nil : exclusion_toggle_path,
          csrf_token: helpers.form_authenticity_token,
          checked: !excluded?,
          enabled: !inherited_exclusion?,
          on_label: exclusion_on_label,
          off_label: exclusion_off_label,
          size: :small,
          status_label_position: :start,
          title: exclusion_description,
          aria: { label: exclusion_toggle_label },
          classes: "op-primer-adjustments__toggle-switch--hidden-loading-indicator",
          data: { test_selector: "toggle-form-config-exclusion-#{exclusion_element_key}" }
        }.compact
      end
    end
  end
end
