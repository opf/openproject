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

require 'roar/decorator'
require 'roar/json/hal'

module API
  module V3
    module Versions
      class VersionRepresenter < ::API::Decorators::Single
        include API::Decorators::LinkedResource

        self_link

        associated_resource :project,
                            as: :definingProject,
                            skip_render: ->(*) { !represented.project.visible?(current_user) }

        link :availableInProjects do
          {
            href: api_v3_paths.projects_by_version(represented.id)
          }
        end

        property :id, render_nil: true
        property :name, render_nil: true

        property :description,
                 exec_context: :decorator,
                 getter: ->(*) {
                   ::API::Decorators::Formattable.new(represented.description,
                                                      object: represented,
                                                      format: 'plain')
                 },
                 render_nil: true

        property :start_date,
                 exec_context: :decorator,
                 getter: ->(*) {
                   datetime_formatter.format_date(represented.start_date, allow_nil: true)
                 },
                 render_nil: true
        property :due_date,
                 as: 'endDate',
                 exec_context: :decorator,
                 getter: ->(*) {
                   datetime_formatter.format_date(represented.due_date, allow_nil: true)
                 },
                 render_nil: true
        property :status, render_nil: true
        property :created_on,
                 as: 'createdAt',
                 exec_context: :decorator,
                 getter: ->(*) { datetime_formatter.format_datetime(represented.created_on) }
        property :updated_on,
                 as: 'updatedAt',
                 exec_context: :decorator,
                 getter: ->(*) { datetime_formatter.format_datetime(represented.updated_on) }

        def _type
          'Version'
        end
      end
    end
  end
end
