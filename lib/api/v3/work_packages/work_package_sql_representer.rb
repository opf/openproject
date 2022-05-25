#  OpenProject is an open source project management software.
#  Copyright (C) 2010-2022 the OpenProject GmbH
#
#  This program is free software; you can redistribute it and/or
#  modify it under the terms of the GNU General Public License version 3.
#
#  OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
#  Copyright (C) 2006-2013 Jean-Philippe Lang
#  Copyright (C) 2010-2013 the ChiliProject Team
#
#  This program is free software; you can redistribute it and/or
#  modify it under the terms of the GNU General Public License
#  as published by the Free Software Foundation; either version 2
#  of the License, or (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
#  See COPYRIGHT and LICENSE files for more details.

module API
  module V3
    module WorkPackages
      class WorkPackageSqlRepresenter
        include API::Decorators::Sql::Hal
        include API::Decorators::Sql::HalAssociatedResource

        link :self,
             path: { api: :work_package, params: %w(id) },
             column: -> { :id },
             title: -> { 'subject' }
        link :project,
             path: { api: :project, params: %w(id) },
             column: -> { :project_id },
             title: -> { 'project_name' },
             join: { table: :projects,
                     condition: 'projects.id = work_packages.project_id',
                     select: ['projects.name project_name'] }

        associated_user_link :author

        associated_user_link :assignee,
                             column_name: :assigned_to_id

        associated_user_link :responsible

        property :_type,
                 representation: ->(*) { "'WorkPackage'" }

        property :id

        property :subject

        property :startDate, column: :start_date,
                             render_if: ->(*) { "startdatesms != true" },
                             join: { table: :types,
                                     condition: 'startDates.id = work_packages.type_id',
                                     select: 'startDates.is_milestone startdatesms' }

        property :dueDate, column: :due_date,
                           render_if: ->(*) { "duedatesms.is_milestone != true" },
                           join: { table: :types,
                                   condition: 'dueDates.id = work_packages.type_id',
                                   select: 'dueDates.is_milestone duedatesms' }

        property :date, column: :start_date,
                        render_if: ->(*) { "datesms.is_milestone = true" },
                        join: { table: :types,
                                condition: 'dates.id = work_packages.type_id',
                                select: 'dates.is_milestone datesms' }
      end
    end
  end
end
