#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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
  module WithSharedWorkPackagesCount
    extend ActiveSupport::Concern

    class_methods do
      def with_shared_work_packages_count(only_role_id: nil)
        Member
          .from("#{Member.table_name} members")
          .joins(shared_work_packages_sql(only_role_id))
          .select('members.*')
          .select('members_sums.shared_work_packages_count AS shared_work_packages_count')
      end

      private

      def shared_work_packages_sql(only_role_id)
        <<~SQL.squish
          LEFT JOIN (
            SELECT members_sums.user_id, members_sums.project_id, COUNT(*) AS shared_work_packages_count
            FROM #{Member.table_name} members_sums
            #{shared_work_packages_role_condition(only_role_id)}
            WHERE members_sums.entity_type = 'WorkPackage'
            GROUP BY members_sums.user_id, members_sums.project_id
          ) members_sums
          ON members.user_id = members_sums.user_id AND members.project_id = members_sums.project_id
        SQL
      end

      def shared_work_packages_role_condition(only_role_id)
        if only_role_id.present?
          sql = <<~SQL.squish
            INNER JOIN #{MemberRole.table_name} members_roles
            ON members_sums.id = members_roles.member_id
            AND members_roles.role_id = ?
          SQL

          OpenProject::SqlSanitization.sanitize sql, only_role_id
        end
      end
    end

    def shared_work_packages_count
      @shared_work_packages_count ||= begin
        value = read_attribute(:shared_work_packages_count) ||
          self.class.with_shared_work_packages_count.where(id:).pick('members_sums.shared_work_packages_count')

        value.to_i
      end
    end
  end
end
