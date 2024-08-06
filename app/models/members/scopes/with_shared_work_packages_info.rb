#-- copyright
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
#++

module Members::Scopes
  module WithSharedWorkPackagesInfo
    extend ActiveSupport::Concern

    class_methods do
      def with_shared_work_packages_info(only_role_id: nil)
        Member
          .from("#{Member.quoted_table_name} members")
          .joins(shared_work_packages_sql(only_role_id))
          .select("members.*")
          .select("COALESCE(members_sums.shared_work_package_ids, '{}') AS shared_work_package_ids")
          .select("COALESCE(members_sums.other_shared_work_packages_count, 0) AS other_shared_work_packages_count")
          .select("COALESCE(members_sums.direct_shared_work_packages_count, 0) AS direct_shared_work_packages_count")
          .select("COALESCE(members_sums.inherited_shared_work_packages_count, 0) AS inherited_shared_work_packages_count")
          .select("COALESCE(members_sums.all_shared_work_packages_count, 0) AS all_shared_work_packages_count")
      end

      private

      def shared_work_packages_sql(only_role_id)
        <<~SQL.squish
          LEFT JOIN (
            SELECT
              members_sums.user_id,
              members_sums.project_id,
              #{shared_work_packages_role_selectors(only_role_id)},
              COUNT(distinct entity_id) AS all_shared_work_packages_count
            FROM #{Member.quoted_table_name} members_sums
            LEFT JOIN #{MemberRole.quoted_table_name} members_roles
              ON members_sums.id = members_roles.member_id
            WHERE members_sums.entity_type = 'WorkPackage'
            GROUP BY members_sums.user_id, members_sums.project_id
          ) members_sums
          ON members.user_id = members_sums.user_id AND members.project_id = members_sums.project_id
        SQL
      end

      def shared_work_packages_role_selectors(only_role_id)
        if only_role_id
          OpenProject::SqlSanitization.sanitize <<~SQL.squish, only_role_id:
            ARRAY_AGG(distinct entity_id)
              FILTER (WHERE members_roles.role_id = :only_role_id)
                AS shared_work_package_ids,
            COUNT(distinct entity_id)
              FILTER (WHERE members_roles.role_id <> :only_role_id)
                AS other_shared_work_packages_count,
            COUNT(distinct entity_id)
              FILTER (WHERE members_roles.role_id = :only_role_id AND members_roles.inherited_from IS NULL)
                AS direct_shared_work_packages_count,
            COUNT(distinct entity_id)
              FILTER (WHERE members_roles.role_id = :only_role_id AND members_roles.inherited_from IS NOT NULL)
                AS inherited_shared_work_packages_count
          SQL
        else
          <<~SQL.squish
            ARRAY_AGG(distinct entity_id)
              AS shared_work_package_ids,
            0
              AS other_shared_work_packages_count,
            COUNT(distinct entity_id)
              FILTER (WHERE members_roles.inherited_from IS NULL)
                AS direct_shared_work_packages_count,
            COUNT(distinct entity_id)
              FILTER (WHERE members_roles.inherited_from IS NOT NULL)
                AS inherited_shared_work_packages_count
          SQL
        end
      end
    end
  end
end
