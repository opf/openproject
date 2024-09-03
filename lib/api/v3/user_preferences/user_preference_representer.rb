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

require "roar/decorator"
require "roar/json/hal"

module API
  module V3
    module UserPreferences
      class UserPreferenceRepresenter < ::API::Decorators::Single
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

        property :hide_mail
        property :time_zone,
                 render_nil: true

        property :warn_on_leaving_unsaved
        property :comments_in_reverse_order,
                 as: :commentSortDescending
        property :auto_hide_popups

        # Also accept times in the format of HH:MM which are also valid according to ISO8601
        # and have those as the only times in the resource.
        property :daily_reminders,
                 getter: ->(*) do
                   reminders = daily_reminders.dup
                   reminders["times"].map! { |time| time.gsub(/\A(\d{2}:\d{2}).*\z/, '\1') } if reminders
                   reminders
                 end,
                 setter: ->(fragment:, **) do
                   self.daily_reminders = fragment

                   daily_reminders["times"].map! { |time| time.gsub(/\A(\d{2}:\d{2})\z/, '\1:00+00:00') }
                 end

        property :immediate_reminders

        property :pause_reminders,
                 getter: ->(*) do
                   pause_reminders.transform_keys { |k| k.camelize(:lower) }
                 end,
                 setter: ->(fragment:, **) do
                   self.pause_reminders = fragment.transform_keys(&:underscore)

                   if pause_reminders["last_day"].blank? && pause_reminders["first_day"]
                     pause_reminders["last_day"] = pause_reminders["first_day"]
                   end
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
      end
    end
  end
end
