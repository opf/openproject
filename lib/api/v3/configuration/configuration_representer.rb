#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'api/decorators/single'

module API
  module V3
    module Configuration
      class ConfigurationRepresenter < ::API::Decorators::Single
        link :self do
          {
            href: api_v3_paths.configuration
          }
        end

        link :userPreferences do
          {
            href: api_v3_paths.my_preferences
          }
        end

        property :maximum_attachment_file_size,
                 getter: ->(*) { attachment_max_size.to_i.kilobyte }

        property :per_page_options,
                 getter: ->(*) { per_page_options_array }

        property :date_format,
                 exec_context: :decorator,
                 render_nil: true

        property :time_format,
                 exec_context: :decorator,
                 render_nil: true

        property :start_of_week,
                 getter: ->(*) {
                   Setting.start_of_week.to_i unless Setting.start_of_week.blank?
                 },
                 render_nil: true

        property :user_preferences,
                 embedded: true,
                 exec_context: :decorator,
                 if: ->(*) {
                   embed_links
                 }

        def _type
          'Configuration'
        end

        def user_preferences
          UserPreferences::UserPreferencesRepresenter.new(current_user.pref,
                                                          current_user: current_user)
        end

        def date_format
          reformated(Setting.date_format) do |directive|
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

        def time_format
          reformated(Setting.time_format) do |directive|
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

        def reformated(setting)
          format = setting.gsub(/%\w/) do |directive|
            yield directive
          end

          format.blank? ? nil : format
        end
      end
    end
  end
end
