#-- copyright
# OpenProject Global Roles Plugin
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

require 'open_project/plugins'

module OpenProject::GlobalRoles
  class Engine < ::Rails::Engine
    engine_name :openproject_global_roles

    include OpenProject::Plugins::ActsAsOpEngine

    register 'openproject-global_roles',
             :author_url => 'http://finn.de',
             :requires_openproject => '>= 4.0.0'

    assets %w(global_roles/global_roles.css global_roles/global_roles.js)

    patches [ :Principal, :Role, :User, :RolesController, :UsersController, :RolesHelper, :UsersHelper]

    initializer 'global_roles.patch_access_control' do
      require 'open_project/global_roles/patches/access_control_patch'
      require 'open_project/global_roles/patches/permission_patch'
    end

    initializer 'global_roles.register_global_permission' do
      Redmine::AccessControl.permission(:add_project).global = true
    end

    config.to_prepare do
      User.register_allowance_evaluator OpenProject::GlobalRoles::PrincipalAllowanceEvaluator::Global
    end
  end
end
