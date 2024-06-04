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

module Queries::Projects::ProjectQueries::Scopes
  module AllowedTo
    extend ActiveSupport::Concern

    class_methods do
      # Returns an ActiveRecord::Relation to find all project queries for which
      # the +user+ either has the given +permission+ directly on the project query
      # or if the project query is owned by the +user+
      def allowed_to(user, permission) # rubocop:disable Metrics/AbcSize
        permissions = Authorization.contextual_permissions(permission, :project_query, raise_on_unknown: true)

        return none if user.locked?
        return none if permissions.empty?

        if user.anonymous?
          # TODO: Possible chance to also allow access to public queries here
          none
        else
          public_queries = where(public: true).select(:id).arel
          user_owned_queries = where(user_id: user.id).select(:id).arel
          allowed_via_membership = allowed_to_member_relation(user, permissions).select(arel_table[:id]).arel

          with(
            public_queries:,
            user_owned_queries:,
            allowed_queries: allowed_via_membership
          ).where("project_queries.id IN (SELECT id FROM public_queries UNION SELECT id FROM user_owned_queries UNION SELECT id FROM allowed_queries)")
        end
      end

      private

      def allowed_to_member_relation(user, permissions)
        Member
          .joins(allowed_to_member_in_query_join)
          .joins(member_roles: :role)
          .joins(allowed_to_role_permission_join(permissions))
          .where(member_conditions(user))
          .select(arel_table[:id])
      end

      def allowed_to_role_permission_join(permissions) # rubocop:disable Metrics/AbcSize
        return if permissions.all?(&:public?)

        role_permissions_table = RolePermission.arel_table
        roles_table = Role.arel_table

        condition = permissions.inject(Arel::Nodes::False.new) do |or_condition, permission|
          permission_condition = role_permissions_table[:permission].eq(permission.name)

          or_condition.or(permission_condition)
        end

        arel_table
          .join(role_permissions_table, Arel::Nodes::InnerJoin)
          .on(roles_table[:id].eq(role_permissions_table[:role_id])
                              .and(condition))
          .join_sources
      end

      def allowed_to_member_in_query_join
        members_table = Member.arel_table
        arel_table.join(arel_table)
        .on(members_table[:entity_id].eq(arel_table[:id]))
        .join_sources
      end

      def member_conditions(user)
        Member.arel_table[:user_id].eq(user.id)
        .and(Member.arel_table[:entity_type].eq(model_name.name))
      end
    end
  end
end
