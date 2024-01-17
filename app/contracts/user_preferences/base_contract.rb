#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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

module UserPreferences
  class BaseContract < ::BaseContract
    property :settings

    validate :user_allowed_to_access
    validates :settings,
              not_nil: true,
              json: {
                schema: ->(*) {
                  UserPreferences::Schema.schema
                },
                if: -> { model.settings.present? }
              }

    validate :time_zone_correctness,
             if: -> { model.time_zone.present? }

    validate :full_hour_reminder_time,
             if: -> { model.daily_reminders.present? }

    validate :no_duplicate_workdays,
             if: -> { model.workdays.is_a?(Array) }

    validate :valid_pause_days,
             if: -> { model.pause_reminders.present? && model.pause_reminders[:enabled] }

    class << self
      ##
      # Returns time zones supported by OpenProject. Those include only the subset of all the
      # TZInfo timezones also handled by ActiveSupport::TimeZone.
      # The reason for this is currently:
      #   * the reminder mail implementation which could be amended
      #   * the select in the form which only displays ActiveSupport::TimeZone as they are more
      #     user friendly.
      # As we only store tzinfo compatible data we only provide options, for which the
      # values can later on be retrieved unambiguously. This is not always the case
      # for values in ActiveSupport::TimeZone since multiple AS zones map to single tzinfo zones.
      def assignable_time_zones
        ActiveSupport::TimeZone
          .all
          .group_by { |tz| tz.tzinfo.name }
          .values
          .map do |zones|
          namesake_time_zone(zones)
        end
      end

      private

      # If there are multiple AS::TimeZones for a single TZInfo::Timezone, we
      # only return the one that is the namesake.
      def namesake_time_zone(time_zones)
        if time_zones.length == 1
          time_zones.first
        else
          time_zones.detect { |tz| tz.tzinfo.name.include?(tz.name.tr(' ', '_')) }
        end
      end
    end

    def assignable_time_zones
      self.class.assignable_time_zones
    end

    protected

    def time_zone_correctness
      if model.time_zone.present? &&
         assignable_time_zones.none? { |tz| tz.tzinfo.canonical_identifier == model.time_zone }
        errors.add(:time_zone, :inclusion)
      end
    end

    ##
    # User preferences can only be accessed with the manage_user permission
    # or if an active, logged user is editing their own prefs
    def user_allowed_to_access
      unless user.allowed_globally?(:manage_user) || (user.logged? && user.active? && user.id == model.user_id)
        errors.add :base, :error_unauthorized
      end
    end

    def full_hour_reminder_time
      unless model.daily_reminders[:times].all? { |time| time.end_with?('00:00+00:00') }
        errors.add :daily_reminders, :full_hour
      end
    end

    def no_duplicate_workdays
      unless model.workdays.uniq.length == model.workdays.length
        errors.add :workdays, :no_duplicates
      end
    end

    def valid_pause_days
      first = model.pause_reminders[:first_day]
      last = model.pause_reminders[:last_day]

      if first.blank? || last.blank?
        errors.add :pause_reminders, :blank
        return
      end

      unless last.to_date >= first.to_date
        errors.add :pause_reminders, :invalid_range
      end
    end
  end
end
