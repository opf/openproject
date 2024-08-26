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

class Queries::WorkPackages::Filter::WatcherFilter <
  Queries::WorkPackages::Filter::PrincipalBaseFilter
  def allowed_values
    @allowed_values ||= begin
      # populate the watcher list with the same user list as other user filters
      # if the user has the :view_work_package_watchers permission
      # in at least one project
      # TODO: this could be differentiated
      # more, e.g. all users could watch issues in public projects,
      # but won't necessarily be shown here
      values = me_allowed_value
      if view_work_package_watchers_allowed?
        values += principal_loader.user_values
      end
      values
    end
  end

  def type
    :list
  end

  def self.key
    :watcher_id
  end

  def where
    if User.current.admin?
      # Admins can always see all watchers
      where_any_watcher
    else
      where_allowed_watchers
    end
  end

  private

  def view_work_package_watchers_allowed?
    if project
      User.current.allowed_in_project?(:view_work_package_watchers, project)
    else
      User.current.allowed_in_any_project?(:view_work_package_watchers)
    end
  end

  def where_any_watcher
    db_table = Watcher.table_name
    db_field = "user_id"

    <<-SQL
      #{WorkPackage.table_name}.id #{operator == '=' ? 'IN' : 'NOT IN'}
        (SELECT #{db_table}.watchable_id
         FROM #{db_table}
         WHERE #{db_table}.watchable_type='WorkPackage'
           AND #{::Queries::Operators::Equals.sql_for_field values_replaced, db_table, db_field})
    SQL
  end

  def where_allowed_watchers
    sql_parts = []

    if User.current.logged? && user_id = values_replaced.delete(User.current.id.to_s)
      # a user can always see his own watched issues
      sql_parts << where_self_watcher(user_id)
    end
    # filter watchers only in projects the user has the permission to view watchers in
    sql_parts << where_watcher_in_view_watchers_allowed

    sql_parts.join(" OR ")
  end

  def where_self_watcher(user_id)
    <<-SQL
      #{WorkPackage.table_name}.id #{operator == '=' ? 'IN' : 'NOT IN'}
        (SELECT #{db_table}.watchable_id
         FROM #{db_table}
         WHERE #{db_table}.watchable_type='WorkPackage'
         AND #{::Queries::Operators::Equals.sql_for_field [user_id], db_table, db_field})
    SQL
  end

  def where_watcher_in_view_watchers_allowed
    <<-SQL
      #{WorkPackage.table_name}.id #{operator == '=' ? 'IN' : 'NOT IN'}
        (SELECT #{db_table}.watchable_id
         FROM #{db_table}
         WHERE #{db_table}.watchable_type='WorkPackage'
           AND #{::Queries::Operators::Equals.sql_for_field values_replaced, db_table, db_field})
           AND #{Project.table_name}.id IN
             (#{view_watcher_allowed_scoped.to_sql})
    SQL
  end

  def db_table
    Watcher.table_name
  end

  def db_field
    "user_id"
  end

  def view_watcher_allowed_scoped
    Project
      .allowed_to(User.current, :view_work_package_watchers)
      .select("#{Project.table_name}.id")
  end
end
