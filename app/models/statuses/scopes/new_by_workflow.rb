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
# See docs/COPYRIGHT.rdoc for more details.
#++

module Statuses::Scopes
  module NewByWorkflow
    extend ActiveSupport::Concern

    class_methods do
      # Returns statuses a work packages can be assigned to. The set of statuses depends on the current status as well
      # as on the workflows that are defined.
      # As the workflows factor in the role and the type as well as sometimes being specific for an assignee or author,
      # those also determine the set of status.
      #
      # @param status [Status] The status the work package currently has. Provide nil if the work package is unpersisted.
      # @param role [Role, Array<Role>] The set of roles for which the workflows are to be defined.
      # @param type [Type] The type for which the workflows are to be defined.
      # @param assignee [Boolean] Whether assignee specific workflows are to be included in the calculation.
      # @param author [Boolean] Whether author specific workflows are to be included in the calculation.
      # @return [ActiveRecord::Relation] A scope of eligible candidates
      def new_by_workflow(status:,
                          role:,
                          type:,
                          assignee: false,
                          author: false)
        workflows = Workflow
                    .where(type: type, role: role)
                    .where(assignee: assignee ? [true, false] : false)
                    .where(author: author ? [true, false] : false)

        if status
          Status.where(id: workflows.where(old_status: status).select(:new_status_id))
            .or(Status.where(id: status.id))
        else
          Status
            .where(id: workflows.select(:new_status_id))
            .or(Status.where(id: workflows.select(:old_status_id)))
        end
      end
    end
  end
end
