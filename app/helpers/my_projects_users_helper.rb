#-- copyright
# OpenProject My Project Page Plugin
#
# Copyright (C) 2011-2015 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
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
# See doc/COPYRIGHT.md for more details.
#++

module MyProjectsUsersHelper
  def users_by_role(limit = 100)
    @users_by_role = Hash.new do |h, size|
      h[size] = if size > 0
                  sql_string = all_roles.map do |r|
                    %Q{ (Select users.*, member_roles.role_id from users
                        JOIN members on users.id = members.user_id
                        JOIN member_roles on member_roles.member_id = members.id
                        WHERE members.project_id = #{project.id} AND member_roles.role_id = #{r.id}
                        LIMIT #{size} ) }
                  end.join(" UNION ALL ")

                  Principal.find_by_sql(sql_string).group_by(&:role_id).inject({}) do |hash, (role_id, users)|
                    hash[all_roles.detect{ |r| r.id == role_id.to_i }] = users.uniq {|user| user.id}
                    hash
                  end
                else
                  project.users_by_role
                end

    end

    @users_by_role[limit]
  end

  def count_users_by_role
    @count_users_per_role ||= begin
      sql_string = all_roles.map do |r|
        %Q{ (Select COUNT(DISTINCT users.id) AS count, member_roles.role_id AS role_id from users
            JOIN members on users.id = members.user_id
            JOIN member_roles on member_roles.member_id = members.id
            WHERE members.project_id = #{project.id} AND member_roles.role_id = #{r.id}
            GROUP BY (member_roles.role_id)) }
      end.join(" UNION ALL ")

      role_count = {}

      ActiveRecord::Base.connection.execute(sql_string).each do |entry|
        if entry.is_a?(Hash)
          # MySql
          count = entry['count'].to_i
          role_id = entry['role_id'].to_i
        else
          # Postgresql
          count = entry.first.to_i
          role_id = entry.last.to_i
        end

        role_count[all_roles.detect{ |r| r.id == role_id }] = count if count > 0
      end

      role_count
    end
  end

  def all_roles
    @all_roles = Role.all
  end
end
