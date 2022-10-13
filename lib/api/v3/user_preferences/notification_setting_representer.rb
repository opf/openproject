#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2022 the OpenProject GmbH
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

module API
  module V3
    module UserPreferences
      class NotificationSettingRepresenter < ::API::Decorators::Single
        include API::Decorators::LinkedResource

        NotificationSetting.all_settings.each do |setting|
          property setting

          property :start_date,
                   exec_context: :decorator,
                   getter: ->(*) do
                     datetime_formatter.format_duration_from_hours(represented.overdue,
                                                                   allow_nil: true)
                   end

          property :due_date,
                   exec_context: :decorator,
                   getter: ->(*) do
                     datetime_formatter.format_duration_from_hours(represented.overdue,
                                                                   allow_nil: true)
                   end

          property :overdue,
                   exec_context: :decorator,
                   getter: ->(*) do
                     datetime_formatter.format_duration_from_hours(represented.overdue,
                                                                   allow_nil: true)
                   end

          def start_date=(value)
            represented.start_date = datetime_formatter.parse_duration_to_days(value,
                                                                               'start_date',
                                                                               allow_nil: true)
          end

          def due_date=(value)
            represented.due_date = datetime_formatter.parse_duration_to_days(value,
                                                                             'due_date',
                                                                             allow_nil: true)
          end

          def overdue=(value)
            represented.overdue = datetime_formatter.parse_duration_to_days(value,
                                                                            'startDate',
                                                                            allow_nil: true)
          end
        end

        associated_resource :project,
                            skip_render: ->(*) { true },
                            skip_link: ->(*) { false }
      end
    end
  end
end
