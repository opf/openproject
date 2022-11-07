# --copyright
# OpenProject is an open source project management software.
# Copyright (C) 2010-2022 the OpenProject GmbH
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

module OpenProject::AccessControl
  module DatabasePermissionMapper
    module_function

    def create_view
      ActiveRecord::Base.connection.execute <<~SQL
        DROP MATERIALIZED VIEW permission_maps;

        CREATE MATERIALIZED VIEW permission_maps AS (
          SELECT
            permission,
            project_module,
            public,
            grant_admin,
            global
          FROM
          VALUES (
            ('view_project', NULL, true, false, false),
            ('view_news', 'news', true, false, false),
            ('view_work_packages', 'work_package_tracking', false, false, false),
            ('add_work_packages', 'work_package_tracking', false, false, false),
            ('work_package_assigned', 'work_package_tracking', false, true, false),
            ('view_wiki_pages', 'wiki', false, false, false),
            ('add_project', NULL, false, false, true)
            )
          ) AS permission_module_map(permission, project_module, public, grant_admin, global);
      SQL
    end
  end
end
