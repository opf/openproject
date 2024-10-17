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

Rails.application.reloader.to_prepare do
  OpenProject::AccessControl.map do |map|
    map.project_module nil, order: 100 do
      map.permission :add_project,
                     { projects: %i[new] },
                     permissible_on: :global,
                     require: :loggedin,
                     contract_actions: { projects: %i[create] }

      map.permission :archive_project,
                     {
                       "projects/archive": %i[create]
                     },
                     permissible_on: :project,
                     require: :member

      map.permission :create_backup,
                     {
                       admin: %i[index],
                       "admin/backups": %i[delete_token perform_token_reset reset_token show]
                     },
                     permissible_on: :global,
                     require: :loggedin,
                     visible: -> { OpenProject::Configuration.backup_enabled? }

      map.permission :create_user,
                     {
                       users: %i[index show new create resend_invitation],
                       "users/memberships": %i[create],
                       admin: %i[index]
                     },
                     permissible_on: :global,
                     require: :loggedin,
                     contract_actions: { users: %i[read create] }

      map.permission :manage_user,
                     {
                       users: %i[index show edit update change_status change_status_info],
                       "users/memberships": %i[create update destroy],
                       admin: %i[index]
                     },
                     permissible_on: :global,
                     require: :loggedin,
                     contract_actions: { users: %i[read update] }

      map.permission :manage_placeholder_user,
                     {
                       placeholder_users: %i[index show new create edit update deletion_info destroy],
                       "placeholder_users/memberships": %i[create update destroy],
                       admin: %i[index]
                     },
                     permissible_on: :global,
                     require: :loggedin,
                     contract_actions: { placeholder_users: %i[create read update] }

      map.permission :view_user_email,
                     {},
                     permissible_on: :global,
                     require: :loggedin

      map.permission :view_project,
                     { projects: [:show] },
                     permissible_on: :project,
                     public: true

      map.permission :search_project,
                     { search: :index },
                     permissible_on: :project,
                     public: true

      map.permission :edit_project,
                     {
                       "projects/settings/general": %i[show],
                       "projects/settings/storage": %i[show],
                       "projects/templated": %i[create destroy],
                       "projects/identifier": %i[show update]
                     },
                     permissible_on: :project,
                     require: :member,
                     contract_actions: { projects: %i[update] }

      map.permission :select_project_modules,
                     {
                       "projects/settings/modules": %i[show update]
                     },
                     permissible_on: :project,
                     require: :member

      map.permission :view_project_attributes,
                     {},
                     permissible_on: :project,
                     dependencies: :view_project

      map.permission :edit_project_attributes,
                     {},
                     permissible_on: :project,
                     require: :member,
                     dependencies: :view_project_attributes,
                     contract_actions: { projects: %i[update] }

      map.permission :select_project_custom_fields,
                     {
                       "projects/settings/project_custom_fields": %i[show toggle enable_all_of_section disable_all_of_section]
                     },
                     permissible_on: :project,
                     require: :member

      map.permission :manage_members,
                     {
                       members: %i[index new create update destroy destroy_by_principal autocomplete_for_member menu],
                       "members/menus": %i[show]
                     },
                     permissible_on: :project,
                     require: :member,
                     dependencies: :view_members,
                     contract_actions: { members: %i[create update destroy] }

      map.permission :view_members,
                     {
                       members: %i[index menu],
                       "members/menus": %i[show]
                     },
                     permissible_on: :project,
                     contract_actions: { members: %i[read] }

      map.permission :manage_versions,
                     {
                       "projects/settings/versions": [:show],
                       versions: %i[new create edit update close_completed destroy]
                     },
                     permissible_on: :project,
                     require: :member

      map.permission :manage_types,
                     {
                       "projects/settings/types": %i[show update]
                     },
                     permissible_on: :project,
                     require: :member

      map.permission :select_custom_fields,
                     {
                       "projects/settings/custom_fields": %i[show update]
                     },
                     permissible_on: :project,
                     require: :member

      map.permission :add_subprojects,
                     { projects: %i[new] },
                     permissible_on: :project,
                     require: :member

      map.permission :copy_projects,
                     {
                       projects: %i[copy]
                     },
                     permissible_on: :project,
                     require: :member,
                     contract_actions: { projects: %i[copy] }

      map.permission :edit_attribute_help_texts,
                     {
                       admin: %i[index],
                       attribute_help_texts: %i[index new edit upsale create update destroy]
                     },
                     permissible_on: :global,
                     require: :loggedin,
                     grant_to_admin: true

      map.permission :manage_public_project_queries,
                     {
                       "projects/queries": %i[toggle_public]
                     },
                     permissible_on: :global,
                     require: :loggedin,
                     grant_to_admin: true

      map.permission :view_project_query,
                     {},
                     permissible_on: :project_query,
                     require: :loggedin

      map.permission :edit_project_query,
                     {},
                     permissible_on: :project_query,
                     require: :loggedin
    end

    map.project_module :work_package_tracking, order: 90 do |wpt|
      wpt.permission :view_work_packages,
                     {
                       versions: %i[index show status_by],
                       journals: %i[index],
                       work_packages: %i[show index],
                       work_packages_api: [:get],
                       "work_packages/reports": %i[report report_details],
                       "work_packages/activities_tab": %i[index update_streams update_sorting update_filter],
                       "work_packages/menus": %i[show],
                       "work_packages/hover_card": %i[show]
                     },
                     permissible_on: %i[work_package project],
                     contract_actions: { work_packages: %i[read] }

      wpt.permission :add_work_packages,
                     {},
                     permissible_on: :project,
                     dependencies: :view_work_packages,
                     contract_actions: { work_packages: %i[create] }

      wpt.permission :edit_work_packages,
                     {
                       "work_packages/bulk": %i[edit update]
                     },
                     permissible_on: %i[work_package project],
                     require: :member,
                     dependencies: :view_work_packages,
                     contract_actions: { work_packages: %i[update] }

      wpt.permission :move_work_packages,
                     { "work_packages/moves": %i[new create] },
                     permissible_on: :project,
                     require: :loggedin,
                     dependencies: :view_work_packages,
                     contract_actions: { work_packages: %i[move] }

      wpt.permission :copy_work_packages,
                     {},
                     permissible_on: %i[work_package project],
                     require: :loggedin,
                     dependencies: :view_work_packages

      wpt.permission :add_work_package_notes,
                     {
                       # FIXME: Although the endpoint is removed, the code checking whether a user
                       # is eligible to add work packages through the API still seems to rely on this.
                       journals: [:new],
                       "work_packages/activities_tab": %i[create]
                     },
                     permissible_on: %i[work_package project],
                     dependencies: :view_work_packages

      wpt.permission :edit_work_package_notes,
                     {
                       "work_packages/activities_tab": %i[edit cancel_edit update]
                     },
                     permissible_on: :project,
                     require: :loggedin,
                     dependencies: :view_work_packages

      wpt.permission :edit_own_work_package_notes,
                     {
                       "work_packages/activities_tab": %i[edit cancel_edit update]
                     },
                     permissible_on: %i[work_package project],
                     require: :loggedin,
                     dependencies: :view_work_packages

      # WP attachments can be added with :edit_work_packages, this permission allows it without Edit WP as well.
      wpt.permission :add_work_package_attachments,
                     {},
                     permissible_on: %i[work_package project],
                     dependencies: :view_work_packages

      # WorkPackage categories
      wpt.permission :manage_categories,
                     {
                       "projects/settings/categories": [:show],
                       categories: %i[new create edit update destroy]
                     },
                     permissible_on: :project,
                     require: :member

      wpt.permission :export_work_packages,
                     {
                       work_packages: %i[index export_dialog all]
                     },
                     permissible_on: %i[work_package project],
                     dependencies: :view_work_packages

      wpt.permission :delete_work_packages,
                     {
                       work_packages: :destroy,
                       "work_packages/bulk": :destroy
                     },
                     permissible_on: :project,
                     require: :member,
                     dependencies: :view_work_packages

      wpt.permission :manage_work_package_relations,
                     {
                       work_package_relations: %i[create destroy]
                     },
                     permissible_on: %i[work_package project],
                     dependencies: :view_work_packages

      wpt.permission :manage_subtasks,
                     {},
                     permissible_on: :project,
                     dependencies: :view_work_packages
      # Queries
      wpt.permission :manage_public_queries,
                     {},
                     permissible_on: :project,
                     require: :member

      wpt.permission :save_queries,
                     {},
                     permissible_on: :project,
                     require: :loggedin,
                     dependencies: :view_work_packages,
                     contract_actions: { queries: %i[create] }
      # Watchers
      wpt.permission :view_work_package_watchers,
                     {},
                     permissible_on: :project,
                     dependencies: :view_work_packages

      wpt.permission :add_work_package_watchers,
                     {},
                     permissible_on: :project,
                     dependencies: :view_work_packages

      wpt.permission :delete_work_package_watchers,
                     {},
                     permissible_on: :project,
                     dependencies: :view_work_packages

      map.permission :share_work_packages,
                     {
                       members: %i[destroy_by_principal]
                     },
                     permissible_on: :project,
                     dependencies: %i[edit_work_packages view_shared_work_packages],
                     require: :member

      map.permission :view_shared_work_packages,
                     {},
                     permissible_on: :project,
                     require: :member,
                     contract_actions: { work_package_shares: %i[index] }

      wpt.permission :assign_versions,
                     {},
                     permissible_on: :project,
                     dependencies: :view_work_packages

      # WP status can be changed with :edit_work_packages, this permission allows it without Edit WP as well.
      wpt.permission :change_work_package_status,
                     {},
                     permissible_on: :project,
                     dependencies: :view_work_packages

      # A user having the following permission can become assignee and/or responsible of a work package.
      # This is a passive permission in the sense that a user having the permission isn't eligible to perform
      # actions but rather to have actions taken together with him/her.
      wpt.permission :work_package_assigned,
                     {},
                     permissible_on: %i[work_package project],
                     require: :member,
                     contract_actions: { work_packages: %i[assigned] },
                     grant_to_admin: false
    end

    map.project_module :news do |news|
      news.permission :view_news,
                      { news: %i[index show] },
                      permissible_on: :project,
                      public: true

      news.permission :manage_news,
                      {
                        news: %i[new create edit update destroy preview],
                        "news/comments": [:destroy]
                      },
                      permissible_on: :project,
                      require: :member

      news.permission :comment_news,
                      { "news/comments": :create },
                      permissible_on: :project
    end

    map.project_module :wiki do |wiki|
      wiki.permission :view_wiki_pages,
                      { wiki: %i[index show special menu] },
                      permissible_on: :project

      wiki.permission :list_attachments,
                      { wiki: :list_attachments },
                      permissible_on: :project,
                      require: :member

      wiki.permission :manage_wiki,
                      { wikis: %i[edit destroy] },
                      permissible_on: :project,
                      require: :member

      wiki.permission :manage_wiki_menu,
                      { wiki_menu_items: %i[edit update select_main_menu_item replace_main_menu_item] },
                      permissible_on: :project,
                      require: :member

      wiki.permission :rename_wiki_pages,
                      { wiki: :rename },
                      permissible_on: :project,
                      require: :member

      wiki.permission :change_wiki_parent_page,
                      { wiki: %i[edit_parent_page update_parent_page] },
                      permissible_on: :project,
                      require: :member

      wiki.permission :delete_wiki_pages,
                      { wiki: :destroy },
                      permissible_on: :project,
                      require: :member

      wiki.permission :export_wiki_pages,
                      { wiki: [:export] },
                      permissible_on: :project

      wiki.permission :view_wiki_edits,
                      { wiki: %i[history diff annotate] },
                      permissible_on: :project

      wiki.permission :edit_wiki_pages,
                      { wiki: %i[edit update preview add_attachment new new_child create] },
                      permissible_on: :project

      wiki.permission :delete_wiki_pages_attachments,
                      {},
                      permissible_on: :project

      wiki.permission :protect_wiki_pages,
                      { wiki: :protect },
                      permissible_on: :project,
                      require: :member
    end

    map.project_module :repository do |repo|
      repo.permission :browse_repository,
                      { repositories: %i[show browse entry annotate changes diff stats graph] },
                      permissible_on: :project

      repo.permission :commit_access,
                      {},
                      permissible_on: :project

      repo.permission :manage_repository,
                      {
                        repositories: %i[edit create update committers destroy_info destroy],
                        "projects/settings/repository": :show
                      },
                      permissible_on: :project,
                      require: :member

      repo.permission :view_changesets,
                      { repositories: %i[show revisions revision] },
                      permissible_on: :project

      repo.permission :view_commit_author_statistics,
                      {},
                      permissible_on: :project
    end

    map.project_module :forums do |forum|
      forum.permission :manage_forums,
                       { forums: %i[new create edit update move destroy] },
                       permissible_on: :project,
                       require: :member

      forum.permission :view_messages,
                       { forums: %i[index show],
                         messages: [:show] },
                       permissible_on: :project,
                       public: true

      forum.permission :add_messages,
                       { messages: %i[new create reply quote preview] },
                       permissible_on: :project

      forum.permission :edit_messages,
                       { messages: %i[edit update preview] },
                       permissible_on: :project,
                       require: :member

      forum.permission :edit_own_messages,
                       { messages: %i[edit update preview] },
                       permissible_on: :project,
                       require: :loggedin

      forum.permission :delete_messages,
                       { messages: :destroy },
                       permissible_on: :project,
                       require: :member

      forum.permission :delete_own_messages,
                       { messages: :destroy },
                       permissible_on: :project,
                       require: :loggedin
    end

    map.project_module :activity do
      map.permission :view_project_activity,
                     { activities: %i[index menu] },
                     permissible_on: :project,
                     public: true,
                     contract_actions: { activities: %i[read] }
    end
  end
end
