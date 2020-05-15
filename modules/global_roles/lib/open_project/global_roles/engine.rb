#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'open_project/plugins'

module OpenProject::GlobalRoles
  class Engine < ::Rails::Engine
    engine_name :openproject_global_roles

    include OpenProject::Plugins::ActsAsOpEngine

    register 'openproject-global_roles',
             author_url: 'https://www.openproject.com',
             bundled: true

    assets %w(global_roles/global_roles.js)

    # We still override version and project settings views from the core! URH
    override_core_views!

    patches %i[Principal User UsersController]
    patch_with_namespace :BasicData, :RoleSeeder

    add_tab_entry :user,
                  name: 'global_roles',
                  partial: 'users/global_roles',
                  path: ->(params) { tab_edit_user_path(params[:user], tab: :global_roles) },
                  label: :global_roles

    initializer 'patch helper' do
      require_relative 'patches/roles_helper_patch'
    end

    global_roles_attributes = [:id, :principal_id, :role_id, role_ids: []]
    additional_permitted_attributes global_roles_principal_role: global_roles_attributes

    initializer 'global_roles.patch_access_control' do
      require 'open_project/global_roles/patches/access_control_patch'
      require 'open_project/global_roles/patches/permission_patch'
    end

    initializer 'global_roles.register_global_permission' do
      OpenProject::AccessControl.permission(:add_project).global = true
    end

    config.to_prepare do
      principal_roles_table = PrincipalRole.arel_table.alias('global_role_principal_roles')
      query = Authorization::UserGlobalRolesQuery
      roles_table = query.roles_table
      users_table = query.users_table

      query.transformations
           .register :all,
                     :principal_roles_join,
                     before: [:roles_join] do |statement, user|

        statement.outer_join(principal_roles_table)
                 .on(users_table[:id].eq(principal_roles_table[:principal_id]))
      end

      query.transformations
           .register query.roles_member_roles_join,
                     :or_is_principal_role do |statement, user|

        statement.or(principal_roles_table[:role_id].eq(roles_table[:id]))
      end
    end
  end
end
