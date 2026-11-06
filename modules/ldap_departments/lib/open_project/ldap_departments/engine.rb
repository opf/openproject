# frozen_string_literal: true

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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module OpenProject::LdapDepartments
  class Engine < ::Rails::Engine
    engine_name :openproject_ldap_departments

    include OpenProject::Plugins::ActsAsOpEngine

    register "openproject-ldap_departments",
             author_url: "https://github.com/opf/openproject",
             bundled: true,
             settings: {
               default: {}
             } do
      menu :admin_menu,
           :plugin_ldap_departments,
           { controller: "/ldap_departments/synchronized_trees", action: :index },
           parent: :authentication,
           after: :plugin_ldap_groups,
           caption: ->(*) { I18n.t("ldap_departments.label_menu_item") },
           enterprise_feature: "ldap_groups"
    end

    add_cron_jobs do
      {
        "LdapDepartments::SynchronizationJob": {
          cron: "*/30 * * * *", # Run every 30 minutes
          class: LdapDepartments::SynchronizationJob.name
        }
      }
    end

    include_module "LdapAuthSources::LdapDepartmentSynchronization", into: "LdapAuthSource"
    include_module "Groups::LdapDepartmentSynchronization", into: "Group"
    include_module "Users::LdapDepartmentMemberships", into: "User"
  end
end
