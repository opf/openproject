# -- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
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

module ProjectQueries::Scopes
  module AllowedTo
    extend ActiveSupport::Concern

    class_methods do
      # Returns an ActiveRecord::Relation to find all project queries for which
      # the +user+ either has the given +permission+ directly on the project query
      # or if the project query is owned by the +user+
      def allowed_to(user, permission)
        permissions = Authorization.contextual_permissions(permission, :project_query, raise_on_unknown: true).map(&:name)

        return none if user.locked?
        return none if permissions.empty?

        if user.anonymous?
          # TODO: Possible chance to also allow access to public queries here
          none
        else
          ctes = if permissions.include?(:edit_project_query)
                   ctes_for_edit_permission(user)
                 else
                   ctes_for_view_permission(user)
                 end

          with(ctes).where(<<~SQL.squish)
            project_queries.id IN (
              SELECT id FROM public_queries
              UNION
              SELECT id FROM user_owned_queries
              UNION
              SELECT id FROM allowed_via_membership
            )
          SQL
        end
      end

      private

      def ctes_for_view_permission(user)
        public_queries = where(public: true).select(:id).arel
        user_owned_queries = where(user_id: user.id).select(:id).arel
        allowed_via_membership = allowed_to_member_relation(user, :view_project_query).select(arel_table[:id]).arel

        { public_queries:, user_owned_queries:, allowed_via_membership: }
      end

      def ctes_for_edit_permission(user) # rubocop:disable Metrics/AbcSize
        can_manage_global_queries = user.allowed_globally?(:manage_public_project_queries)

        public_queries = if can_manage_global_queries
                           where(public: true).select(:id).arel
                         else
                           none.select(:id).arel
                         end

        user_owned_queries = if can_manage_global_queries
                               where(user_id: user.id).select(:id).arel
                             else
                               where(user_id: user.id, public: false).select(:id).arel
                             end

        allowed_via_membership = allowed_to_member_relation(user, :edit_project_query).select(arel_table[:id]).arel

        { public_queries:, user_owned_queries:, allowed_via_membership: }
      end

      def allowed_to_member_relation(user, permission)
        Member
          .joins(allowed_to_member_in_query_join(user))
          .joins(member_roles: :role)
          .joins(allowed_to_role_permission_join(permission))
          .select(arel_table[:id])
      end

      def allowed_to_role_permission_join(permission)
        role_permissions_table = RolePermission.arel_table
        roles_table = Role.arel_table

        arel_table
          .join(role_permissions_table, Arel::Nodes::InnerJoin)
          .on(roles_table[:id].eq(role_permissions_table[:role_id])
                              .and(role_permissions_table[:permission].eq(permission.name)))
          .join_sources
      end

      def allowed_to_member_in_query_join(user) # rubocop:disable Metrics/AbcSize
        members_table = Member.arel_table

        join_conditions = members_table[:user_id].eq(user.id)
          .and(members_table[:entity_type].eq(model_name.name))
          .and(members_table[:entity_id].eq(arel_table[:id]))

        arel_table.join(arel_table).on(join_conditions).join_sources
      end
    end
  end
end
