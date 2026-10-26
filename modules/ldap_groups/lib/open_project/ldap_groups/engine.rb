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

module OpenProject::LdapGroups
  class Engine < ::Rails::Engine
    engine_name :openproject_ldap_groups

    include OpenProject::Plugins::ActsAsOpEngine

    initializer "ldap_groups.settings_search" do
      ::Settings::Pages.draw do
        page :ldap_groups, menu_item: :plugin_ldap_groups do
          link :new_filter,
               label: :"ldap_groups.synchronized_filters.add_new",
               url: -> { new_ldap_groups_synchronized_filter_path },
               if: -> { EnterpriseToken.allows_to?(:ldap_groups) }
          link :new_group,
               label: :"ldap_groups.synchronized_groups.add_new",
               url: -> { new_ldap_groups_synchronized_group_path },
               if: -> { EnterpriseToken.allows_to?(:ldap_groups) }
        end
      end

      ::Settings::EntityKinds.draw do
        kind :ldap_synchronized_filters,
             menu_item: :plugin_ldap_groups,
             scope: -> { LdapGroups::SynchronizedFilter.order(:name) },
             url: ->(filter) { edit_ldap_groups_synchronized_filter_path(filter) },
             if: -> { EnterpriseToken.allows_to?(:ldap_groups) } do
          %i[name group_name_attribute sync_users ldap_auth_source_id base_dn member_lookup_attribute
             filter_string].each do |name|
            attribute name,
                      label: -> { LdapGroups::SynchronizedFilter.human_attribute_name(name) },
                      field: "synchronized_filter[#{name}]"
          end
        end
      end
    end

    register "openproject-ldap_groups",
             author_url: "https://github.com/opf/openproject-ldap_groups",
             bundled: true,
             settings: {
               default: {}
             } do
      menu :admin_menu,
           :plugin_ldap_groups,
           { controller: "/ldap_groups/synchronized_groups", action: :index },
           parent: :authentication,
           after: :ldap_authentication,
           caption: ->(*) { I18n.t("ldap_groups.label_menu_item") },
           enterprise_feature: "ldap_groups"
    end

    add_cron_jobs do
      {
        "LdapGroups::SynchronizationJob": {
          cron: "*/30 * * * *", # Run every 30 minutes
          class: LdapGroups::SynchronizationJob.name
        }
      }
    end

    include_module "LdapAuthSources::LdapGroupSynchronization", into: "LdapAuthSource"
    include_module "Groups::LdapGroupSynchronization", into: "Group"
    include_module "Users::LdapGroupMemberships", into: "User"
  end
end
