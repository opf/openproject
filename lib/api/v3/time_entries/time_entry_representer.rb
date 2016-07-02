#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'roar/decorator'
require 'roar/json/hal'

module API
  module V3
    module TimeEntries
      class TimeEntryRepresenter < ::API::Decorators::Single
        self_link title_getter: -> (*) { represented.comments }

        linked_property :definingProject,
                        path: :project,
                        getter: :project,
                        show_if: -> (*) { represented.project.visible?(current_user) }

        linked_property :definingWorkPackage,
                        path: :work_package,
                        getter: :work_package,
                        title_getter: -> (*) { represented.work_package.subject }

        linked_property :definingUser,
                        path: :user,
                        getter: :user

        property :id, render_nil: true
        property :hours, render_nil: true

        property :comments,
                 exec_context: :decorator,
                 getter: -> (*) {
                   ::API::Decorators::Formattable.new(represented.comments,
                                                      object: represented,
                                                      format: 'plain')
                 },
                 render_nil: true

        property :spent_on,
                 as: 'spendOn',
                 exec_context: :decorator,
                 getter: -> (*) { datetime_formatter.format_datetime(represented.spent_on, allow_nil: true) }
        property :created_on,
                 as: 'createdAt',
                 exec_context: :decorator,
                 getter: -> (*) { datetime_formatter.format_datetime(represented.created_on) }
        property :updated_on,
                 as: 'updatedAt',
                 exec_context: :decorator,
                 getter: -> (*) { datetime_formatter.format_datetime(represented.updated_on) }

        def _type
          'TimeEntry'
        end

        self.to_eager_load = [:project,
                              :work_package,
                              :user]
      end
    end
  end
end
