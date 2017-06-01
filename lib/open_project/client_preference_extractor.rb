#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See doc/COPYRIGHT.rdoc for more details.
#++

module OpenProject
  module ClientPreferenceExtractor
    def client_preferences
      gon.settings = {
        user_preferences: user_preferences,
        display: {
          date_format: momentjstify_date_format(Setting.date_format),
          time_format: momentjstify_time_format(Setting.time_format),
          start_of_week: Setting.start_of_week
        },
        pagination: {
          per_page_options: Setting.per_page_options_array
        }
      }
    end

    def user_preferences(user = User.current)
      pref = user.pref.clone

      map_timezone_to_tz!(pref)
    end

    def map_timezone_to_tz!(pref)
      unless pref.time_zone.blank?
        pref.time_zone = ActiveSupport::TimeZone::MAPPING[pref.time_zone]
      end

      pref
    end

    def momentjstify_date_format(date_format)
      date_format.gsub(/%\w/) do |directive|
        case directive
        when '%Y'
          'YYYY'
        when '%y'
          'YY'
        when '%m'
          'MM'
        when '%B'
          'MMMM'
        when '%b', '%h'
          'MMM'
        when '%d'
          'DD'
        when '%e'
          'D'
        when '%j'
          'DDDD'
        end
      end
    end

    def momentjstify_time_format(time_format)
      time_format.gsub(/%\w/) do |directive|
        case directive
        when '%H'
          'HH'
        when '%k'
          'H'
        when '%I'
          'hh'
        when '%l'
          'h'
        when '%P'
          'A'
        when '%p'
          'a'
        when '%M'
          'mm'
        end
      end
    end
  end
end
