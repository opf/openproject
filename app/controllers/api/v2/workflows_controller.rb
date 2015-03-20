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

module Api
  module V2
    class WorkflowsController < WorkflowsController
      include ::Api::V2::ApiController

      Workflow = Struct.new(:type_id, :old_status_id, :transitions)

      Transition = Struct.new(:new_status_id, :scope)

      skip_before_filter :require_admin, only: :index

      before_filter :find_project_by_project_id,
                    :require_permissions

      accept_key_auth :index

      def index
        workflows = ::Workflow.where(type_id: @project.types.map(&:id),
                                     role_id: User.current.roles(@project).map(&:id))
                    .select(workflow_select_statement)
                    .group('type_id, old_status_id, new_status_id')

        workflows_by_type_and_old_status = workflows.group_by(&:type_id).each_with_object({}) do |kv, h|
          h[kv[0]] = kv[1].group_by(&:old_status_id)
        end

        @workflows = workflows_by_type_and_old_status.each_with_object([]) do |kv, l|
          kv[1].each_pair do |old_status_id, workflows|
            transitions = workflows.each_with_object([]) do |w, t|
              t << Transition.new(w.new_status_id, scope(w))
            end

            l << Workflow.new(kv[0], old_status_id, transitions)
          end
        end

        respond_to do |format|
          format.api
        end
      end

      protected

      def require_permissions
        deny_access unless @project.visible?
      end

      private

      def workflow_select_statement
        stmt = 'type_id, old_status_id, new_status_id, '

        if ActiveRecord::Base.connection.instance_values['config'][:adapter] == 'postgresql'
          stmt += 'MAX(CAST(assignee AS INT)) AS assignee, MAX(CAST(author AS INT)) AS author'
        else
          stmt += 'MAX(assignee) AS assignee, MAX(author) AS author'
        end

        stmt
      end

      def scope(transition)
        if transition.author
          :author
        elsif transition.assignee
          :assignee
        else
          :role
        end
      end
    end
  end
end
