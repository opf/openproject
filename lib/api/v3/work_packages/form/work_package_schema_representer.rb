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
    module WorkPackages
      module Form
        class WorkPackageSchemaRepresenter < ::API::Decorators::Single
          property :_type,
                   getter: -> (*) { { type: 'MetaType', required: true, writable: false } },
                   writeable: false
          property :lock_version,
                   getter: -> (*) { { type: 'Integer', required: true, writable: false } },
                   writeable: false
          property :subject,
                   getter: -> (*) { { type: 'String' } },
                   writeable: false
          property :description,
                   getter: -> (*) { { type: 'Formattable' } },
                   writeable: false
          property :status,
                   exec_context: :decorator,
                   getter: -> (*) {
                     status_origin = represented

                     if represented.persisted? && represented.status_id_changed?
                       status_origin = represented.class.find(represented.id)
                     end

                     new_statuses = status_origin.new_statuses_allowed_to(current_user)

                     SchemaAllowedStatusesRepresenter.new(new_statuses,
                                                          current_user: current_user)
                   }

          property :assignee,
                   exec_context: :decorator,
                   getter: -> (*) {
                     link = api_v3_paths.available_assignees(represented.project.id)

                     ::API::Decorators::AllowedReferenceLinkRepresenter.new(link, 'User')
                   }

          property :responsible,
                   exec_context: :decorator,
                   getter: -> (*) {
                     link = api_v3_paths.available_responsibles(represented.project.id)

                     ::API::Decorators::AllowedReferenceLinkRepresenter.new(link, 'User')
                   }

          property :version,
                   exec_context: :decorator,
                   getter: -> (*) {
                     version_origin = represented

                     if represented.persisted? && represented.fixed_version_id_changed?
                       version_origin = represented.class.find(represented.id)
                     end

                     SchemaAllowedVersionsRepresenter.new(version_origin.assignable_versions,
                                                          current_user: current_user)
                   }

          def current_user
            context[:current_user]
          end

          def _type
            'MetaType'
          end
        end
      end
    end
  end
end
