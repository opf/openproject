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

module API
  module V3
    module TimeEntries
      class TimeEntryRepresenter < ::API::Decorators::Single
        include API::Decorators::LinkedResource

        class << self
          def create_class(work_package)
            injector_class = ::API::V3::Utilities::CustomFieldInjector
            injector_class.create_value_representer(work_package,
                                                    self)
          end

          def create(work_package, current_user:, embed_links: false)
            create_class(work_package)
              .new(work_package,
                   current_user: current_user,
                   embed_links: embed_links)
          end
        end

        self_link title_getter: ->(*) { nil }

        defaults render_nil: true

        property :id

        property :comments,
                 as: :comment

        property :spent_on,
                 exec_context: :decorator,
                 getter: ->(*) do
                   datetime_formatter.format_date(represented.spent_on, allow_nil: true)
                 end

        property :hours,
                 exec_context: :decorator,
                 getter: ->(*) do
                   datetime_formatter.format_duration_from_hours(represented.hours)
                 end

        property :created_at,
                 exec_context: :decorator,
                 getter: ->(*) do
                   datetime_formatter.format_datetime(represented.created_on, allow_nil: true)
                 end

        property :updated_at,
                 exec_context: :decorator,
                 getter: ->(*) do
                   datetime_formatter.format_datetime(represented.updated_on, allow_nil: true)
                 end

        associated_resource :project

        associated_resource :work_package,
                            link_title_attribute: :subject

        associated_resource :user

        associated_resource :activity,
                            representer: TimeEntriesActivityRepresenter,
                            v3_path: :time_entries_activity,
                            getter: associated_resource_default_getter(:authoritativ_activity, TimeEntriesActivityRepresenter),
                            link: ->(*) {
                              activity = represented.authoritativ_activity
                              {
                                href: api_v3_paths.time_entries_activity(activity.id),
                                title: activity.name
                              }
                            }

        def _type
          'TimeEntry'
        end
      end
    end
  end
end
