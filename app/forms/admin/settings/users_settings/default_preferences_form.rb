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

module Admin
  module Settings
    class UsersSettings::DefaultPreferencesForm < ApplicationForm
      include Redmine::I18n

      settings_form do |sf|
        sf.fieldset_group(title: I18n.t(:"settings.user.default_preferences")) do |fg|
          fg.select_list(
            name: :default_language,
            values: all_lang_options_for_select
          )
          fg.select_list(
            name: :user_default_timezone,
            include_blank: true,
            values: time_zone_entries,
            caption: I18n.t(:tooltip_user_default_timezone)
          )
          fg.check_box(
            name: :default_auto_hide_popups,
            label: UserPreference.human_attribute_name(:auto_hide_popups)
          )
        end
      end

      private

      def all_lang_options_for_select
        all_languages
          .map { |lang| translate_language(lang) }
          .sort_by(&:first)
      end

      def time_zone_entries
        UserPreferences::UpdateContract
          .assignable_time_zones
          .group_by { |tz| tz.tzinfo.canonical_zone }
          .map { |canonical_zone, included_zones| time_zone_option(canonical_zone, included_zones) }
      end

      def time_zone_option(canonical_zone, zones)
        zone_names = zones.map(&:name).join(", ")
        [
          "(UTC#{ActiveSupport::TimeZone.seconds_to_utc_offset(canonical_zone.base_utc_offset)}) #{zone_names}",
          canonical_zone.identifier
        ]
      end
    end
  end
end
