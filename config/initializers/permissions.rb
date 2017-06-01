#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'redmine/access_control'

Redmine::AccessControl.map do |map|
  map.permission :view_project,
                 { projects: [:show],
                   activities: [:index] },
                 public: true

  map.permission :search_project,
                 { search: :index },
                 public: true

  map.permission :add_project,
                 { projects: [:new, :create],
                   members: [:paginate_users] },
                 require: :loggedin

  map.permission :edit_project,
                 { projects: [:settings, :edit, :update, :custom_fields],
                   members: [:paginate_users] },
                 require: :member

  map.permission :select_project_modules,
                 { projects: :modules },
                 require: :member

  map.permission :manage_members,
                 { members: [:index, :new, :create, :update, :destroy, :autocomplete_for_member] },
                 require: :member

  map.permission :view_members,
                 { members: [:index] },
                 require: :member

  map.permission :manage_versions,
                 { projects: :settings,
                   versions: [:new, :create, :edit, :update,
                              :close_completed, :destroy] },
                 require: :member

  map.permission :manage_types,
                 { projects: :types },
                 require: :member

  map.permission :add_subprojects,
                 { projects: [:new, :create] },
                 require: :member

  map.permission :copy_projects,
                 { copy_projects: [:copy, :copy_project],
                   members: [:paginate_users] },
                 require: :member

  map.project_module :work_package_tracking do |wpt|
    # Issue categories
    wpt.permission :manage_categories,
                   { projects: :settings,
                     categories: [:new, :create, :edit, :update, :destroy] },
                   require: :member
    # Issues
    wpt.permission :view_work_packages,
                   issues: [:index, :all, :show],
                   auto_complete: [:issues],
                   versions: [:index, :show, :status_by],
                   journals: [:index, :diff],
                   work_packages: [:show, :index],
                   work_packages_api: [:get],
                   :'work_packages/reports' => [:report, :report_details],
                   planning_elements: [:index, :all, :show, :recycle_bin],
                   planning_element_journals: [:index],
                   # This is api/v2/planning_element_types
                   planning_element_types: [:index,
                                               :show]

    wpt.permission :export_work_packages,
                   work_packages: [:index, :all]

    wpt.permission :add_work_packages,
                   issues: [:new, :create],
                   :'issues/previews' => :create,
                   work_packages: [:new, :new_type, :preview, :create]

    wpt.permission :move_work_packages,
                   { :'work_packages/moves' => [:new, :create] },
                   require: :loggedin

    wpt.permission :edit_work_packages,
                   { issues: [:edit, :update],
                     :'work_packages/bulk' => [:edit, :update],
                     work_packages: [:edit, :update, :new_type,
                                     :preview, :quoted],
                     journals: :preview,
                     planning_elements: [:new, :create, :edit, :update],
                     planning_element_journals: [:create] },
                   require: :member

    wpt.permission :add_work_package_notes,
                   work_packages: [:edit, :update],
                   journals: [:new]

    wpt.permission :edit_work_package_notes,
                   { journals: [:edit, :update] },
                   require: :loggedin

    wpt.permission :edit_own_work_package_notes,
                   { journals: [:edit, :update] },
                   require: :loggedin

    wpt.permission :delete_work_packages,
                   { issues: :destroy,
                     work_packages: :destroy,
                     :'work_packages/bulk' => :destroy,
                     planning_elements: [:confirm_destroy,
                                         :destroy,
                                         :destroy_all,
                                         :confirm_destroy_all] },
                   require: :member

    wpt.permission :manage_work_package_relations,
                   work_package_relations: [:create, :destroy]

    wpt.permission :manage_subtasks,
                   {}
    # Queries
    wpt.permission :manage_public_queries,
                   { queries: [:star, :unstar] },
                   require: :member

    wpt.permission :save_queries,
                   { queries: [:star, :unstar] },
                   require: :loggedin
    # Watchers
    wpt.permission :view_work_package_watchers,
                   {}

    wpt.permission :add_work_package_watchers,
                   {}

    wpt.permission :delete_work_package_watchers,
                   {}
  end

  map.project_module :time_tracking do |time|
    time.permission :log_time,
                    { timelog: [:new, :create, :edit, :update] },
                    require: :loggedin

    time.permission :view_time_entries,
                    timelog: [:index, :show],
                    time_entry_reports: [:report]

    time.permission :edit_time_entries,
                    { timelog: [:new, :create, :edit, :update, :destroy] },
                    require: :member

    time.permission :edit_own_time_entries,
                    { timelog: [:new, :create, :edit, :update, :destroy] },
                    require: :loggedin

    time.permission :manage_project_activities,
                    { project_enumerations: [:update, :destroy] },
                    require: :member
  end

  map.project_module :news do |news|
    news.permission :manage_news,
                    { news: [:new, :create, :edit, :update, :destroy, :preview],
                      :'news/comments' => [:destroy] },
                    require: :member

    news.permission :view_news,
                    { news: [:index, :show] },
                    public: true

    news.permission :comment_news,
                    :'news/comments' => :create
  end

  map.project_module :wiki do |wiki|
    wiki.permission :manage_wiki,
                    { wikis: [:edit, :destroy] },
                    require: :member

    wiki.permission :manage_wiki_menu,
                    { wiki_menu_items: [:edit, :update, :select_main_menu_item,
                                        :replace_main_menu_item] },
                    require: :member

    wiki.permission :rename_wiki_pages,
                    { wiki: :rename },
                    require: :member

    wiki.permission :change_wiki_parent_page,
                    { wiki: [:edit_parent_page, :update_parent_page] },
                    require: :member

    wiki.permission :delete_wiki_pages,
                    { wiki: :destroy },
                    require: :member

    wiki.permission :view_wiki_pages,
                    wiki: [:index, :show, :special, :date_index]

    wiki.permission :export_wiki_pages,
                    wiki: [:export]

    wiki.permission :view_wiki_edits,
                    wiki: [:history, :diff, :annotate]

    wiki.permission :edit_wiki_pages,
                    wiki: [:edit, :update, :preview, :add_attachment,
                           :new, :new_child, :create]

    wiki.permission :delete_wiki_pages_attachments,
                    {}

    wiki.permission :protect_wiki_pages,
                    { wiki: :protect },
                    require: :member

    wiki.permission :list_attachments,
                    { wiki: :list_attachments },
                    require: :member
  end

  map.project_module :repository do |repo|
    repo.permission :browse_repository,
                    repositories: [:show, :browse, :entry, :annotate,
                                   :changes, :diff, :stats, :graph]

    repo.permission :commit_access,
                    {}

    repo.permission :manage_repository,
                    { repositories: [:edit, :create, :update, :committers,
                                     :destroy_info, :destroy] },
                    require: :member

    repo.permission :view_changesets,
                    repositories: [:show, :revisions, :revision]


    repo.permission :view_commit_author_statistics,
                    {}
  end

  map.project_module :boards do |board|
    board.permission :manage_boards,
                     { boards: [:new, :create, :edit, :update, :move, :destroy] },
                     require: :member

    board.permission :view_messages,
                     { boards: [:index, :show],
                       messages: [:show] },
                     public: true

    board.permission :add_messages,
                     messages: [:new, :create, :reply, :quote, :preview]

    board.permission :edit_messages,
                     { messages: [:edit, :update, :preview] },
                     require: :member

    board.permission :edit_own_messages,
                     { messages: [:edit, :update, :preview] },
                     require: :loggedin

    board.permission :delete_messages,
                     { messages: :destroy },
                     require: :member

    board.permission :delete_own_messages,
                     { messages: :destroy },
                     require: :loggedin
  end

  map.project_module :calendar do |cal|
    cal.permission :view_calendar,
                   :'work_packages/calendars' => [:index]
  end

  map.project_module :activity

  map.project_module :timelines do |timelines|
    timelines.permission :view_project_associations,
                         project_associations: [:index, :show]

    timelines.permission :edit_project_associations,
                         { project_associations: [:edit, :update, :new,
                                                  :create,
                                                  :available_projects] },
                         require: :member

    timelines.permission :delete_project_associations,
                         { project_associations: [:confirm_destroy, :destroy] },
                         require: :member

    timelines.permission :view_timelines,
                         timelines: [:index, :show]

    timelines.permission :edit_timelines,
                         { timelines: [:edit, :update, :new, :create] },
                         require: :member

    timelines.permission :delete_timelines,
                         { timelines: [:confirm_destroy, :destroy] },
                         require: :member

    timelines.permission :view_reportings,
                         reportings: [:index, :all, :show]

    timelines.permission :edit_reportings,
                         { reportings: [:new, :create, :edit,
                                        :update, :available_projects] },
                         require: :member

    timelines.permission :delete_reportings,
                         { reportings: [:confirm_destroy, :destroy] },
                         require: :member
  end
end
