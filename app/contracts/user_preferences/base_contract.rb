#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2021 the OpenProject GmbH
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
             if: -> { model.workdays.present? }

    protected

    def time_zone_correctness
      errors.add(:time_zone, :inclusion) if model.time_zone.present? && model.canonical_time_zone.nil?
    end

    ##
    # User preferences can only be accessed with the manage_user permission
    # or if an active, logged user is editing their own prefs
    def user_allowed_to_access
      unless user.allowed_to_globally?(:manage_user) || (user.logged? && user.active? && user.id == model.user_id)
        errors.add :base, :error_unauthorized
      end
    end

    def full_hour_reminder_time
      unless model.daily_reminders[:times].all? { |time| time.match?(/00:00\+00:00\z/) }
        errors.add :daily_reminders, :full_hour
      end
    end

    def no_duplicate_workdays
      unless model.workdays.uniq.length == model.workdays.length
        errors.add :workdays, :no_duplicates
      end
    end
  end
end
