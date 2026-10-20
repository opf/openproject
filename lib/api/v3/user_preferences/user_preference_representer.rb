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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "roar/decorator"
require "roar/json/hal"

module API
  module V3
    module UserPreferences
      class UserPreferenceRepresenter < ::API::Decorators::Single
        include API::Decorators::DateProperty

        link :self do
          {
            href: api_v3_paths.user_preferences(represented.user.id)
          }
        end

        link :user do
          {
            href: api_v3_paths.user(represented.user.id),
            title: represented.user.name
          }
        end

        link :updateImmediately do
          {
            href: api_v3_paths.user_preferences(represented.user.id),
            method: :patch
          }
        end

        property :time_zone,
                 render_nil: true

        property :date_format,
                 getter: ->(*) { date_format.presence },
                 render_nil: true

        property :time_format,
                 getter: ->(*) { time_format.presence },
                 render_nil: true

        property :disable_keyboard_shortcuts

        property :require_double_click_for_inline_edit

        property :warn_on_leaving_unsaved
        property :comments_in_reverse_order,
                 as: :commentSortDescending
        property :auto_hide_popups

        property :daily_reminders_enabled

        property :daily_reminders_times,
                 exec_context: :decorator,
                 getter: ->(*) { render_reminder_times(represented.daily_reminders_times) },
                 setter: ->(fragment:, **) { represented.daily_reminders_times = parse_reminder_times(fragment) }

        property :immediate_reminders_mentioned

        property :immediate_reminders_personal_reminder

        property :pause_reminders_enabled

        date_property :pause_reminders_first_day

        date_property :pause_reminders_last_day

        # Deprecated in favour of the flat reminder properties above, kept for API compatibility.
        property :daily_reminders,
                 exec_context: :decorator,
                 getter: ->(*) do
                   {
                     "enabled" => represented.daily_reminders_enabled,
                     "times" => render_reminder_times(represented.daily_reminders_times)
                   }
                 end,
                 setter: ->(fragment:, **) do
                   represented.daily_reminders_enabled = fragment["enabled"]
                   represented.daily_reminders_times = parse_reminder_times(fragment["times"])
                 end

        property :immediate_reminders,
                 getter: ->(*) do
                   {
                     "mentioned" => immediate_reminders_mentioned,
                     "personalReminder" => immediate_reminders_personal_reminder
                   }
                 end,
                 setter: ->(fragment:, **) do
                   self.immediate_reminders_mentioned = fragment["mentioned"] if fragment.key?("mentioned")
                   if fragment.key?("personalReminder")
                     self.immediate_reminders_personal_reminder = fragment["personalReminder"]
                   end
                 end

        property :pause_reminders,
                 getter: ->(*) do
                   {
                     "enabled" => pause_reminders_enabled,
                     "firstDay" => pause_reminders_first_day&.iso8601,
                     "lastDay" => pause_reminders_last_day&.iso8601
                   }.compact
                 end,
                 setter: ->(fragment:, **) do
                   self.pause_reminders_enabled = fragment["enabled"]
                   self.pause_reminders_first_day = fragment["firstDay"]
                   self.pause_reminders_last_day = fragment["lastDay"].presence || fragment["firstDay"]
                 end

        property :workdays

        property :notification_settings,
                 as: :notifications,
                 exec_context: :decorator,
                 getter: ->(*) do
                   represented.notification_settings.map do |setting|
                     NotificationSettingRepresenter.new(setting, current_user:)
                   end
                 end,
                 setter: ->(fragment:, **) do
                   represented.notification_settings = fragment.map do |setting_fragment|
                     NotificationSettingRepresenter
                       .new(OpenStruct.new, current_user:)
                       .from_hash(setting_fragment.with_indifferent_access)
                       .to_h
                   end
                 end

        def _type
          "UserPreferences"
        end

        # Times are rendered as HH:MM, which is valid ISO8601, and accepted in both formats.
        def render_reminder_times(times)
          times.map { |time| time.gsub(/\A(\d{2}:\d{2}).*\z/, '\1') }
        end

        def parse_reminder_times(times)
          Array(times).map { |time| time.gsub(/\A(\d{2}:\d{2})\z/, '\1:00+00:00') }
        end
      end
    end
  end
end
