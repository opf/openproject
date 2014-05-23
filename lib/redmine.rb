#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2014 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'redmine/access_control'
require 'redmine/menu_manager'
require 'redmine/activity'
require 'redmine/search'
require 'redmine/custom_field_format'
require 'redmine/mime_type'
require 'redmine/core_ext'
require 'open_project/themes'
require 'redmine/hook'
require 'open_project/hooks'
require 'redmine/plugin'
require 'redmine/notifiable'
require 'redmine/wiki_formatting'
require 'redmine/scm/base'

require 'csv'
require 'globalize'

Redmine::Scm::Base.add "Subversion"
Redmine::Scm::Base.add "Git"
Redmine::Scm::Base.add "Filesystem"

Redmine::CustomFieldFormat.map do |fields|
  fields.register Redmine::CustomFieldFormat.new('string', :label => :label_string, :order => 1)
  fields.register Redmine::CustomFieldFormat.new('text', :label => :label_text, :order => 2)
  fields.register Redmine::CustomFieldFormat.new('int', :label => :label_integer, :order => 3)
  fields.register Redmine::CustomFieldFormat.new('float', :label => :label_float, :order => 4)
  fields.register Redmine::CustomFieldFormat.new('list', :label => :label_list, :order => 5)
  fields.register Redmine::CustomFieldFormat.new('date', :label => :label_date, :order => 6)
  fields.register Redmine::CustomFieldFormat.new('bool', :label => :label_boolean, :order => 7)
  fields.register Redmine::CustomFieldFormat.new('user', :label => Proc.new { User.model_name.human }, :only => %w(WorkPackage TimeEntry Version Project), :edit_as => 'list', :order => 8)
  fields.register Redmine::CustomFieldFormat.new('version', :label => Proc.new { Version.model_name.human }, :only => %w(WorkPackage TimeEntry Version Project), :edit_as => 'list', :order => 9)
end

# Permissions
Redmine::AccessControl.map do |map|
  map.permission :view_project,
                 {
                   :types => [:index, :show],
                   :projects => [:show],
                   :projects => [:show],
                   :activities => [:index]
                 },
                 :public => true
  map.permission :search_project, {:search => :index}, :public => true
  map.permission :add_project, {
                                :projects => [:new, :create],
                                :members => [:paginate_users]
                               }, :require => :loggedin
  map.permission :edit_project,
                 {
                   :projects => [:settings, :edit, :update],
                   :members => [:paginate_users]
                 },
                 :require => :member
  map.permission :select_project_modules, {:projects => :modules}, :require => :member
  map.permission :manage_members, {:projects => :settings, :members => [:create, :update, :destroy, :autocomplete_for_member]}, :require => :member
  map.permission :manage_versions, {:projects => :settings, :versions => [:new, :create, :edit, :update, :close_completed, :destroy]}, :require => :member
  map.permission :manage_types, {:projects => :types}, :require => :member
  map.permission :add_subprojects, {:projects => [:new, :create]}, :require => :member
  map.permission :copy_projects, {
                                  :copy_projects => [:copy, :copy_project],
                                  :members => [:paginate_users]
                                 }, :require => :member
  map.permission :load_column_data, {
                 :work_packages => [ :column_data ]
                 }
  map.permission :load_column_sums, {
                 :work_packages => [ :column_sums ]
                 }

  map.project_module :work_package_tracking do |map|
    # Issue categories
    map.permission :manage_categories, {:projects => :settings, :categories => [:new, :create, :edit, :update, :destroy]}, :require => :member
    # Issues
    map.permission :view_work_packages, {:'issues' => [:index, :all, :show],
                                         :auto_complete => [:issues],
                                         :versions => [:index, :show, :status_by],
                                         :journals => [:index, :diff],
                                         :queries => [:index, :create, :update, :available_columns, :custom_field_filters, :grouped],
                                         :work_packages => [:show, :index],
                                         :'work_packages/reports' => [:report, :report_details],
                                         :planning_elements => [:index, :all, :show, :recycle_bin],
                                         :planning_element_journals => [:index]}
    map.permission :export_work_packages, {:'work_packages' => [:index, :all]}
    map.permission :add_work_packages, { :issues => [:new, :create, :update_form],
                                         :'issues/previews' => :create,
                                         :work_packages => [:new, :new_type, :preview, :create] }
    map.permission :move_work_packages, {:'work_packages/moves' => [:new, :create]}, :require => :loggedin
    map.permission :edit_work_packages, { :issues => [:edit, :update, :update_form],
                                          :'work_packages/bulk' => [:edit, :update],
                                          :work_packages => [:edit, :update, :new_type, :preview, :quoted],
                                          :journals => :preview,
                                          :planning_elements => [:new, :create, :edit, :update],
                                          :planning_element_journals => [ [:create], {:require => :member} ] }
    map.permission :add_work_package_notes, {:work_packages => [:edit, :update], :journals => [:new]}
    map.permission :edit_work_package_notes, {:journals => [:edit, :update]}, :require => :loggedin
    map.permission :edit_own_work_package_notes, {:journals => [:edit, :update]}, :require => :loggedin
    map.permission :delete_work_packages, {:issues => :destroy,
                                           :work_packages => :destroy,
                                          :'work_packages/bulk' => :destroy,
                                           :planning_elements => [:confirm_destroy,
                                                                  :destroy,
                                                                  :destroy_all,
                                                                  :confirm_destroy_all]},
                                           :require => :member
    map.permission :manage_work_package_relations, {:work_package_relations => [:create, :destroy]}
    map.permission :manage_subtasks, {}
    # Queries
    map.permission :manage_public_queries, {:queries => [:new, :edit, :destroy]}, :require => :member
    map.permission :save_queries, {:queries => [:new, :edit, :destroy]}, :require => :loggedin
    # Watchers
    map.permission :view_work_package_watchers, {}
    map.permission :add_work_package_watchers, {:watchers => [:new, :create]}
    map.permission :delete_work_package_watchers, {:watchers => :destroy}
  end

  map.project_module :time_tracking do |map|
    map.permission :log_time, {:timelog => [:new, :create, :edit, :update]}, :require => :loggedin
    map.permission :view_time_entries, :timelog => [:index, :show], :time_entry_reports => [:report]
    map.permission :edit_time_entries, {:timelog => [:new, :create, :edit, :update, :destroy]}, :require => :member
    map.permission :edit_own_time_entries, {:timelog => [:new, :create, :edit, :update, :destroy]}, :require => :loggedin
    map.permission :manage_project_activities, {:project_enumerations => [:update, :destroy]}, :require => :member
  end

  map.project_module :news do |map|
    map.permission :manage_news, {:news => [:new, :create, :edit, :update, :destroy, :preview], :'news/comments' => [:destroy]}, :require => :member
    map.permission :view_news, {:news => [:index, :show]}, :public => true
    map.permission :comment_news, {:'news/comments' => :create}
  end

  map.project_module :wiki do |map|
    map.permission :manage_wiki, {:wikis => [:edit, :destroy]}, :require => :member
    map.permission :manage_wiki_menu, {:wiki_menu_items => [:edit, :update, :select_main_menu_item, :replace_main_menu_item]}, :require => :member
    map.permission :rename_wiki_pages, {:wiki => :rename}, :require => :member
    map.permission :change_wiki_parent_page, {:wiki => [:edit_parent_page, :update_parent_page]},
                   :require => :member
    map.permission :delete_wiki_pages, {:wiki => :destroy}, :require => :member
    map.permission :view_wiki_pages, :wiki => [:index, :show, :special, :date_index]
    map.permission :export_wiki_pages, :wiki => [:export]
    map.permission :view_wiki_edits, :wiki => [:history, :diff, :annotate]
    map.permission :edit_wiki_pages, :wiki => [:edit, :update, :preview, :add_attachment, :new, :new_child, :create]
    map.permission :delete_wiki_pages_attachments, {}
    map.permission :protect_wiki_pages, {:wiki => :protect}, :require => :member
    map.permission :list_attachments, {:wiki => :list_attachments}, :require => :member
  end

  map.project_module :repository do |map|
    map.permission :manage_repository, {:repositories => [:edit, :committers, :destroy]}, :require => :member
    map.permission :browse_repository, :repositories => [:show, :browse, :entry, :annotate, :changes, :diff, :stats, :graph]
    map.permission :view_changesets, :repositories => [:show, :revisions, :revision]
    map.permission :commit_access, {}
    map.permission :view_commit_author_statistics, {}
  end

  map.project_module :boards do |map|
    map.permission :manage_boards, {:boards => [:new, :create, :edit, :update, :move, :destroy]}, :require => :member
    map.permission :view_messages, {:boards => [:index, :show], :messages => [:show]}, :public => true
    map.permission :add_messages, {:messages => [:new, :create, :reply, :quote, :preview]}
    map.permission :edit_messages, {:messages => [:edit, :update, :preview]}, :require => :member
    map.permission :edit_own_messages, {:messages => [:edit, :update, :preview]}, :require => :loggedin
    map.permission :delete_messages, {:messages => :destroy}, :require => :member
    map.permission :delete_own_messages, {:messages => :destroy}, :require => :loggedin
  end

  map.project_module :calendar do |map|
    map.permission :view_calendar, :'work_packages/calendars' => [:index]
  end

  map.project_module :activity

  map.project_module :timelines do |map|
    map.permission :view_project_associations,
                   {:project_associations => [:index, :show]}
    map.permission :edit_project_associations,
                   {:project_associations => [:edit, :update, :new,
                                              :create, :available_projects]},
                   {:require => :member}
    map.permission :delete_project_associations,
                   {:project_associations => [:confirm_destroy, :destroy]},
                   {:require => :member}

    map.permission :view_timelines,
                   {:timelines => [:index, :show]}
    map.permission :edit_timelines,
                   {:timelines => [:edit, :update, :new, :create]},
                   {:require => :member}
    map.permission :delete_timelines,
                   {:timelines => [:confirm_destroy, :destroy]},
                   {:require => :member}

    map.permission :view_reportings,
                   {:reportings => [:index, :all, :show]}
    map.permission :edit_reportings,
                   {:reportings => [:new, :create, :edit, :update, :available_projects]},
                   {:require => :member}
    map.permission :delete_reportings,
                   {:reportings => [:confirm_destroy, :destroy]},
                   {:require => :member}
  end
end

Redmine::MenuManager.map :top_menu do |menu|
  menu.push :my_page, { :controller => '/my', :action => 'page' }, :html => {:class => 'icon5 icon-star2'}, :if => Proc.new { User.current.logged? }
  # projects menu will be added by Redmine::MenuManager::TopMenuHelper#render_projects_top_menu_node
  menu.push :administration, { :controller => '/admin', :action => 'projects' }, :if => Proc.new { User.current.admin? }, :last => true
  menu.push :help, OpenProject::Info.help_url, :last => true, :caption => I18n.t('label_help'), :html => { :accesskey => OpenProject::AccessKeys.key_for(:help), :class => "icon5 icon-help"}
end

Redmine::MenuManager.map :account_menu do |menu|
  menu.push :my_account, { :controller => '/my', :action => 'account' }, :if => Proc.new { User.current.logged? }
  menu.push :logout, :signout_path, :if => Proc.new { User.current.logged? }
end

Redmine::MenuManager.map :application_menu do |menu|
  # Empty
end

Redmine::MenuManager.map :my_menu do |menu|
  menu.push :account, {:controller => '/my', :action => 'account'}, :caption => :label_my_account, :html => {:class => "icon2 icon-user1"}
  menu.push :password, {:controller => '/my', :action => 'password'}, :caption => :button_change_password, :if => Proc.new { User.current.change_password_allowed? }, :html => {:class => "icon2 icon-locked"}
  menu.push :delete_account, :deletion_info_path,
                             :caption => I18n.t('account.delete'),
                             :param => :user_id,
                             :if => Proc.new { Setting.users_deletable_by_self? },
                             :html => {:class => 'icon2 icon-delete'}
end

Redmine::MenuManager.map :admin_menu do |menu|
  menu.push :projects, {:controller => '/admin', :action => 'projects'}, :caption => :label_project_plural, :html => {:class => "icon2 icon-list-view2"}
  menu.push :users, {:controller => '/users'}, :caption => :label_user_plural, :html => {:class => "icon2 icon-user1"}
  menu.push :groups, {:controller => '/groups'}, :caption => :label_group_plural, :html => {:class => "icon2 icon-group"}
  menu.push :roles, {:controller => '/roles'}, :caption => :label_role_and_permissions, :html => {:class => "icon2 icon-settings"}
  menu.push :types, {:controller => '/types'}, :caption => :label_type_plural, :html => {:class => "icon2 icon-tracker"}
  menu.push :statuses, {:controller => '/statuses'}, :caption => :label_work_package_status_plural,
            :html => {:class => 'statuses icon2 icon-status'}
  menu.push :workflows, {:controller => '/workflows', :action => 'edit'}, :caption => Proc.new { Workflow.model_name.human }, :html => {:class => "icon2 icon-status"}
  menu.push :custom_fields, {:controller => '/custom_fields'},  :caption => :label_custom_field_plural,
            :html => {:class => 'custom_fields icon2 icon-status' }
  menu.push :enumerations, {:controller => '/enumerations'}, :html => {:class => "icon2 icon-status"}
  menu.push :settings, {:controller => '/settings'}, :html => {:class => "icon2 icon-settings2"}
  menu.push :ldap_authentication, {:controller => '/ldap_auth_sources', :action => 'index'},
            :html => {:class => 'server_authentication icon2 icon-status'}
  menu.push :plugins, {:controller => '/admin', :action => 'plugins'}, :last => true, :html => {:class => "icon2 icon-status"}
  menu.push :info, {:controller => '/admin', :action => 'info'}, :caption => :label_information_plural, :last => true, :html => {:class => "icon2 icon-info"}
  menu.push :colors,
            {:controller => '/planning_element_type_colors', :action => 'index'},
            {:caption    => :'timelines.admin_menu.colors', :html => {:class => "icon2 icon-status"}}
  menu.push :project_types,
            {:controller => '/project_types', :action => 'index'},
            {:caption    => :'timelines.admin_menu.project_types', :html => {:class => "icon2 icon-tracker"}}
end

Redmine::MenuManager.map :project_menu do |menu|
  menu.push :overview, { :controller => '/projects', :action => 'show' },
                       :html => {:class => "icon2 icon-list-view2"}

  menu.push :activity, { :controller => '/activities', :action => 'index' },
                       :param => :project_id,
                       :if => Proc.new { |p| p.module_enabled?("activity") },
                       :html => {:class => "icon2 icon-yes"}

  menu.push :roadmap, { :controller => '/versions', :action => 'index' },
                      :param => :project_id,
                      :if => Proc.new { |p| p.shared_versions.any? },
                      :html => {:class => "icon2 icon-process-arrow1"}

  menu.push :work_packages, { controller: '/work_packages', action: 'index', set_filter: 1 },
                            param: :project_id,
                            caption: :label_work_package_plural,
                            html: {class: "icon2 icon-copy"}

  menu.push :new_work_package, { :controller => '/work_packages', :action => 'new'},
                               :param => :project_id,
                               :caption => :label_work_package_new,
                               :parent => :work_packages,
                               :html => { :accesskey => OpenProject::AccessKeys.key_for(:new_work_package), :class => "icon2 icon-add" }

  menu.push :summary_field, {:controller => '/work_packages/reports', :action => 'report'},
                            :param => :project_id,
                            :caption => :label_workflow_summary,
                            :parent => :work_packages,
                            :html => { :class => "icon2 icon-stats4" }

  menu.push :timelines, {:controller => '/timelines', :action => 'index'},
                        :param => :project_id,
                        :caption => :'timelines.project_menu.timelines',
                        :html => {:class => "icon2 icon-new-planning-element"}

  menu.push :calendar, { :controller => '/work_packages/calendars', :action => 'index' },
                       :param => :project_id,
                       :caption => :label_calendar,
                       :html => {:class => "icon2 icon-calendar"}

  menu.push :news, { :controller => '/news', :action => 'index' },
                   :param => :project_id,
                   :caption => :label_news_plural,
                   :html => {:class => "icon2 icon-news"}

  menu.push :new_news, { :controller => '/news', :action => 'new' },
                       :param => :project_id,
                       :caption => :label_news_new,
                       :parent => :news,
                       :if => Proc.new { |p| User.current.allowed_to?(:manage_news, p.project) },
                       :html => {:class => "icon2 icon-add"}

  menu.push :boards, { :controller => '/boards', :action => 'index', :id => nil },
                     :param => :project_id,
                     :if => Proc.new { |p| p.boards.any? },
                     :caption => :label_board_plural,
                     :html => {:class => "icon2 icon-ticket-note"}

  menu.push :repository, { :controller => '/repositories', :action => 'show' },
                         :param => :project_id,
                         :if => Proc.new { |p| p.repository && !p.repository.new_record? },
                         :html => {:class => "icon2 icon-open-folder"}

  menu.push :reportings, {:controller => '/reportings', :action => 'index'},
                         :param => :project_id,
                         :caption => :'timelines.project_menu.reportings',
                         :html => {:class => "icon2 icon-stats"}


  menu.push :project_associations, {:controller => '/project_associations', :action => 'index'},
                                   :param => :project_id,
                                   :caption => :'timelines.project_menu.project_associations',
                                   :if => Proc.new { |p| p.project_type.try :allows_association },
                                   :html => {:class => "icon2 icon-dependency"}

  menu.push :settings, { :controller => '/projects', :action => 'settings' },
                       :caption => :label_project_settings,
                       :last => true,
                       :html => {:class => "icon2 icon-settings2"}
end

Redmine::Activity.map do |activity|
  activity.register :work_packages, class_name: 'Activity::WorkPackageActivityProvider'
  activity.register :changesets, class_name: 'Activity::ChangesetActivityProvider'
  activity.register :news, class_name: 'Activity::NewsActivityProvider', default: false
  activity.register :wiki_edits, class_name: 'Activity::WikiContentActivityProvider', default: false
  activity.register :messages, class_name: 'Activity::MessageActivityProvider', default: false
  activity.register :time_entries, class_name: 'Activity::TimeEntryActivityProvider', default: false
end

Redmine::Search.map do |search|
  search.register :work_packages
  search.register :news
  search.register :changesets
  search.register :wiki_pages
  search.register :messages
  search.register :projects
end

Redmine::WikiFormatting.map do |format|
  format.register :textile, Redmine::WikiFormatting::Textile::Formatter, Redmine::WikiFormatting::Textile::Helper
end
