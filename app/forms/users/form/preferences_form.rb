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

module Users
  module Form
    # Preferences section of the administration user form: time zone, color mode
    # and keyboard shortcuts. Bound to the user's preference (scope: :pref).
    #
    # My::LookAndFeelForm could not be reused directly because it renders its own
    # submit button and extra fields (comments sorting, contrast); the time zone
    # option building mirrors My::TimeZoneForm.
    class PreferencesForm < ApplicationForm
      form do |f|
        f.fieldset_group(title: I18n.t(:label_preferences), mb: 3) do |group|
          group.select_list(
            name: :time_zone,
            label: UserPreference.human_attribute_name(:time_zone),
            include_blank: false,
            input_width: :medium
          ) do |list|
            time_zone_options.each { |label, value| list.option(label:, value:) }
          end

          group.select_list(
            name: :theme,
            label: UserPreference.human_attribute_name(:theme),
            caption: UserPreference.human_attribute_name(:mode_guideline),
            include_blank: false,
            input_width: :medium
          ) do |list|
            helpers.theme_options_for_select.each { |label, value| list.option(label:, value:) }
          end

          group.check_box(
            name: :disable_keyboard_shortcuts,
            label: UserPreference.human_attribute_name(:disable_keyboard_shortcuts),
            caption: helpers.link_translate(:"user_preferences.disable_keyboard_shortcuts_caption",
                                            links: { docs_url: %i[shortcuts] })
          )
        end
      end

      private

      def time_zone_options
        UserPreferences::UpdateContract
          .assignable_time_zones
          .group_by { |zone| zone.tzinfo.canonical_zone }
          .map { |canonical_zone, zones| time_zone_entry(canonical_zone, zones) }
      end

      def time_zone_entry(canonical_zone, zones)
        zone_names = zones.map(&:name).join(", ")
        offset = ActiveSupport::TimeZone.seconds_to_utc_offset(canonical_zone.base_utc_offset)

        ["(UTC#{offset}) #{zone_names}", canonical_zone.identifier]
      end
    end
  end
end
