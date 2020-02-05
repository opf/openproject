#-- encoding: UTF-8
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

require 'open_project/access_control'

def edit_project_hash
  permissions = {
    projects: %i[edit update custom_fields],
    project_settings: [:show],
    members: [:paginate_users]
  }

  ProjectSettingsHelper.project_settings_tabs.each do |node|
    permissions["project_settings/#{node[:name]}"] = [:show]
  end
  permissions
end

OpenProject::AccessControl.map do |map|
  map.project_module nil, order: 100 do
    map.permission :view_project,
                   { projects: [:show],
                     activities: [:index] },
                   public: true

    map.permission :search_project,
                   { search: :index },
                   public: true

    map.permission :add_project,
                   { projects: %i[new create],
                     members: [:paginate_users] },
                   require: :loggedin

    map.permission :edit_project,
                   edit_project_hash,
                   require: :member

    map.permission :select_project_modules,
                   { projects: :modules },
                   require: :member

    map.permission :manage_members,
                   { members: %i[index new create update destroy autocomplete_for_member] },
                   require: :member,
                   dependencies: :view_members

    map.permission :view_members,
                   { members: [:index] }

    map.permission :manage_versions,
                   {
                     "project_settings/versions": [:show],
                     versions: %i[new create edit update close_completed destroy]
                   },
                   require: :member

    map.permission :manage_types,
                   { projects: :types },
                   require: :member

    map.permission :add_subprojects,
                   { projects: %i[new create] },
                   require: :member

    map.permission :copy_projects,
                   {
                     copy_projects: %i[copy copy_project],
                     members: [:paginate_users]
                   },
                   require: :member
  end

  map.project_module :work_package_tracking, order: 90 do |wpt|
    # Issues
    wpt.permission :view_work_packages,
                   versions: %i[index show status_by],
                   journals: %i[index diff],
                   work_packages: %i[show index],
                   work_packages_api: [:get],
                   :'work_packages/reports' => %i[report report_details]

    wpt.permission :add_work_packages,
                   work_packages: %i[new new_type preview create],
                   planning_elements: [:create]

    wpt.permission :edit_work_packages,
                   {
                     :'work_packages/bulk' => %i[edit update],
                     work_packages: %i[edit update new_type preview quoted],
                     journals: :preview
                   },
                   require: :member,
                   dependencies: :view_work_packages

    wpt.permission :move_work_packages,
                   { :'work_packages/moves' => %i[new create] },
                   require: :loggedin

    wpt.permission :add_work_package_notes,
                   work_packages: %i[edit update],
                   journals: [:new]

    wpt.permission :edit_work_package_notes,
                   { journals: %i[edit update] },
                   require: :loggedin

    wpt.permission :edit_own_work_package_notes,
                   { journals: %i[edit update] },
                   require: :loggedin

    # WorkPackage categories
    wpt.permission :manage_categories,
                   { "project_settings/categories": [:show],
                     categories: %i[new create edit update destroy] },
                   require: :member

    wpt.permission :export_work_packages,
                   work_packages: %i[index all]

    wpt.permission :delete_work_packages,
                   {
                     work_packages: :destroy,
                     :'work_packages/bulk' => :destroy
                   },
                   require: :member,
                   dependencies: :view_work_packages

    wpt.permission :manage_work_package_relations,
                   work_package_relations: %i[create destroy]

    wpt.permission :manage_subtasks,
                   {}
    # Queries
    wpt.permission :manage_public_queries,
                   {},
                   require: :member

    wpt.permission :save_queries,
                   {},
                   require: :loggedin
    # Watchers
    wpt.permission :view_work_package_watchers,
                   {},
                   dependencies: :view_work_packages

    wpt.permission :add_work_package_watchers,
                   {},
                   dependencies: :view_work_packages

    wpt.permission :delete_work_package_watchers,
                   {},
                   dependencies: :view_work_packages

    wpt.permission :assign_versions,
                   {}
  end

  map.project_module :time_tracking do |time|
    time.permission :view_time_entries,
                    timelog: %i[index show],
                    time_entry_reports: [:report]

    time.permission :log_time,
                    { timelog: %i[new create edit update] },
                    require: :loggedin

    time.permission :edit_time_entries,
                    { timelog: %i[new create edit update destroy] },
                    require: :member

    time.permission :view_own_time_entries,
                    timelog: %i[index report]

    time.permission :edit_own_time_entries,
                    { timelog: %i[new create edit update destroy] },
                    require: :loggedin

    time.permission :manage_project_activities,
                    { 'projects/time_entry_activities': %i[update] },
                    require: :member
  end

  map.project_module :news do |news|
    news.permission :view_news,
                    { news: %i[index show] },
                    public: true

    news.permission :manage_news,
                    {
                      news: %i[new create edit update destroy preview],
                      :'news/comments' => [:destroy]
                    },
                    require: :member

    news.permission :comment_news,
                    :'news/comments' => :create
  end

  map.project_module :wiki do |wiki|
    wiki.permission :view_wiki_pages,
                    wiki: %i[index show special date_index]

    wiki.permission :list_attachments,
                    { wiki: :list_attachments },
                    require: :member

    wiki.permission :manage_wiki,
                    { wikis: %i[edit destroy] },
                    require: :member

    wiki.permission :manage_wiki_menu,
                    { wiki_menu_items: %i[edit update select_main_menu_item replace_main_menu_item] },
                    require: :member

    wiki.permission :rename_wiki_pages,
                    { wiki: :rename },
                    require: :member

    wiki.permission :change_wiki_parent_page,
                    { wiki: %i[edit_parent_page update_parent_page] },
                    require: :member

    wiki.permission :delete_wiki_pages,
                    { wiki: :destroy },
                    require: :member

    wiki.permission :export_wiki_pages,
                    wiki: [:export]

    wiki.permission :view_wiki_edits,
                    wiki: %i[history diff annotate]

    wiki.permission :edit_wiki_pages,
                    wiki: %i[edit update preview add_attachment new new_child create]

    wiki.permission :delete_wiki_pages_attachments,
                    {}

    wiki.permission :protect_wiki_pages,
                    { wiki: :protect },
                    require: :member
  end

  map.project_module :repository do |repo|
    repo.permission :browse_repository,
                    repositories: %i[show browse entry annotate changes diff stats graph]

    repo.permission :commit_access,
                    {}

    repo.permission :manage_repository,
                    { repositories: %i[edit create update committers destroy_info destroy] },
                    require: :member

    repo.permission :view_changesets,
                    repositories: %i[show revisions revision]

    repo.permission :view_commit_author_statistics,
                    {}
  end

  map.project_module :forums do |forum|
    forum.permission :manage_forums,
                     { forums: %i[new create edit update move destroy] },
                     require: :member

    forum.permission :view_messages,
                     { forums: %i[index show],
                       messages: [:show] },
                     public: true

    forum.permission :add_messages,
                     messages: %i[new create reply quote preview]

    forum.permission :edit_messages,
                     { messages: %i[edit update preview] },
                     require: :member

    forum.permission :edit_own_messages,
                     { messages: %i[edit update preview] },
                     require: :loggedin

    forum.permission :delete_messages,
                     { messages: :destroy },
                     require: :member

    forum.permission :delete_own_messages,
                     { messages: :destroy },
                     require: :loggedin
  end

  map.project_module :calendar do |cal|
    cal.permission :view_calendar,
                   :'work_packages/calendars' => [:index]
  end

  map.project_module :activity
end
