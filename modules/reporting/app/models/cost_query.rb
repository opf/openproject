#-- copyright
# OpenProject Reporting Plugin
#
# Copyright (C) 2010 - 2014 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# version 3.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#++

class CostQuery < Report
  def_delegators :result, :real_costs

  User.before_destroy do |user|
    CostQuery.where(user_id: user.id, is_public: false).delete_all
    CostQuery.where(['user_id = ?', user.id]).update_all ['user_id = ?', DeletedUser.first.id]

    max_query_id = 0
    while((current_queries = CostQuery.limit(1000)
                             .where(["id > ?", max_query_id])
                             .order("id ASC")).size > 0) do

      current_queries.each do |query|
        serialized = query.serialized

        serialized[:filters] = serialized[:filters].map do |name, options|
          options[:values].delete(user.id.to_s) if ["UserId", "AuthorId", "AssignedToId"].include?(name)

          options[:values].nil? || options[:values].size > 0 ?
            [name, options] :
            nil
        end.compact

        CostQuery.where(["id = ?", query.id]).update_all ["serialized = ?", YAML::dump(serialized)]

        max_query_id = query.id
      end
    end
  end
end
