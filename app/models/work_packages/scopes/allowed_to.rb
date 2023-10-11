# -- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2010-2023 the OpenProject GmbH
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
# ++

module WorkPackages::Scopes
  module AllowedTo
    extend ActiveSupport::Concern
    include Authorization::Scopes::AllowedTo

    class_methods do
      private

      def allowed_to_anonymous(user, permissions)
        where(project_id: Project.allowed_to(user, permissions).select(:id))
      end

      alias_method :allowed_to_non_member_relation, :allowed_to_anonymous

      def allowed_to_admin_relation(permissions)
        joins(:project)
          .joins(allowed_to_enabled_module_join(permissions))
          .where(Project.arel_table[:active].eq(true))
      end

      def allowed_to_member_relation(user, permission)
        super
          .joins(allowed_to_member_in_work_package_join)
      end

      def allowed_to_members_condition(user)
        members_table = Member.arel_table

        members_table[:project_id].eq(arel_table[:project_id])
                                  .and(members_table[:user_id].eq(user.id))
                                  .and(members_table[:entity_type].eq(model_name.name))
      end

      def allowed_to_member_in_work_package_join
        members_table = Member.arel_table

        arel_table.join(arel_table)
                  .on(members_table[:entity_id].eq(arel_table[:id]).and(members_table[:entity_type].eq(model_name.name)))
                  .join_sources
      end
    end
  end
end
