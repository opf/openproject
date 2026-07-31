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
    # The switch each linked attribute row renders to control exclusion of one element.
    #
    # +element_key+ the attribute or query key ("assignee", "custom_field_3", "query_7");
    # +label+ Readable attribute label for the aria-label of the toggle
    class ExclusionToggleComponent < ApplicationComponent
      ASPECT = Type::ConfigurationLink::FORM_CONFIGURATION

      def initialize(exclusions:, element_key:, label:)
        super

        @exclusions = exclusions
        @element_key = element_key
        @label = label
      end

      # Exclusion or element_key being empty means the type owns its configuration, so there is nothing to render
      def render?
        @exclusions.present? && @element_key.present?
      end

      def call
        render(Primer::Alpha::ToggleSwitch.new(**toggle_arguments))
      end

      private

      def toggle_arguments
        {
          src: toggle_path,
          csrf_token: helpers.form_authenticity_token,
          checked: !excluded?,
          on_label: "",
          off_label: t("types.edit.form_configuration.exclusions.excluded"),
          size: :small,
          status_label_position: :start,
          aria: { label: @label },
          classes: "op-primer-adjustments__toggle-switch--hidden-loading-indicator",
          data: { test_selector: test_selector }
        }
      end

      def excluded?
        @exclusions.excluded?(@element_key)
      end

      def toggle_path
        type_excluded_element_toggle_path(type_id: @exclusions.type.id, aspect: ASPECT, element: @element_key)
      end

      def test_selector
        "toggle-form-config-exclusion-#{@element_key}"
      end
    end
  end
end
