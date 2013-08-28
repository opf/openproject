#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
#
# Copyright (C) 2012-2013 the OpenProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
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
require 'redmine/plugin'
require 'redmine/notifiable'
require 'redmine/wiki_formatting'
require 'redmine/scm/base'

begin
  require 'RMagick' unless Object.const_defined?(:Magick)
rescue LoadError
  # RMagick is not available
end

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
  map.permission :add_project, {:projects => [:new, :create]}, :require => :loggedin
  map.permission :edit_project,
                 {
                   :projects => [:settings, :edit, :update]
                 },
                 :require => :member
  map.permission :select_project_modules, {:projects => :modules}, :require => :member
  map.permission :manage_members, {:projects => :settings, :members => [:create, :update, :destroy, :autocomplete_for_member]}, :require => :member
  map.permission :manage_versions, {:projects => :settings, :versions => [:new, :create, :edit, :update, :close_completed, :destroy]}, :require => :member
  map.permission :add_subprojects, {:projects => [:new, :create]}, :require => :member

  map.project_module :issue_tracking do |map|
    # Issue categories
    map.permission :manage_categories, {:projects => :settings, :issue_categories => [:new, :create, :edit, :update, :destroy]}, :require => :member
    # Issues
    map.permission :view_work_packages, {:'issues' => [:index, :all, :show],
                                         :auto_complete => [:issues],
                                         :context_menus => [:issues],
                                         :versions => [:index, :show, :status_by],
                                         :journals => [:index, :diff],
                                         :queries => :index,
                                         :work_packages => [:show],
                                         :'issues/reports' => [:report, :report_details]}
    map.permission :export_issues, {:'issues' => [:index, :all]}
    map.permission :add_issues, {:issues => [:new, :create, :update_form],
                                 :'issues/previews' => :create}
    map.permission :add_work_packages, { :work_packages => [:new, :new_type, :preview, :create] }
    map.permission :move_work_packages, {:'work_packages/moves' => [:new, :create]}, :require => :loggedin
    map.permission :edit_work_packages, { :issues => [:edit, :update, :bulk_edit, :bulk_update, :update_form, :quoted],
                                          :work_packages => [:edit, :update, :new_type, :preview],
                                          :'issues/previews' => :create}
    map.permission :manage_issue_relations, {:issue_relations => [:create, :destroy]}
    map.permission :manage_work_package_relations, {:work_package_relations => [:create, :destroy]}
    map.permission :manage_subtasks, {}
    map.permission :add_issue_notes, {:issues => [:edit, :update], :journals => [:new]}
    map.permission :edit_issue_notes, {:journals => [:edit, :update]}, :require => :loggedin
    map.permission :edit_own_issue_notes, {:journals => [:edit, :update]}, :require => :loggedin
    map.permission :move_issues, {:'issues/moves' => [:new, :create]}, :require => :loggedin
    map.permission :delete_issues, {:issues => :destroy}, :require => :member
    # Queries
    map.permission :manage_public_queries, {:queries => [:new, :edit, :destroy]}, :require => :member
    map.permission :save_queries, {:queries => [:new, :edit, :destroy]}, :require => :loggedin
    # Watchers
    map.permission :view_issue_watchers, {}
    map.permission :view_work_package_watchers, {}
    map.permission :add_work_package_watchers, {:watchers => [:new, :create]}
    map.permission :delete_issue_watchers, {:watchers => :destroy}
  end

  map.project_module :time_tracking do |map|
    map.permission :log_time, {:timelog => [:new, :create, :edit, :update]}, :require => :loggedin
    map.permission :view_time_entries, :timelog => [:index, :show], :time_entry_reports => [:report]
    map.permission :edit_time_entries, {:timelog => [:new, :create, :edit, :update, :destroy]}, :require => :member
    map.permission :edit_own_time_entries, {:timelog => [:new, :create, :edit, :update, :destroy]}, :require => :loggedin
    map.permission :manage_project_activities, {:project_enumerations => [:update, :destroy]}, :require => :member
  end

  map.project_module :news do |map|
    map.permission :manage_news, {:news => [:new, :create, :edit, :update, :destroy], :'news/comments' => [:destroy]}, :require => :member
    map.permission :view_news, {:news => [:index, :show]}, :public => true
    map.permission :comment_news, {:'news/comments' => :create}
  end

  map.project_module :wiki do |map|
    map.permission :manage_wiki, {:wikis => [:edit, :destroy]}, :require => :member
    map.permission :manage_wiki_menu, {:wiki_menu_items => [:edit, :update]}, :require => :member
    map.permission :rename_wiki_pages, {:wiki => :rename}, :require => :member
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
  end

  map.project_module :boards do |map|
    map.permission :manage_boards, {:boards => [:new, :create, :edit, :update, :destroy]}, :require => :member
    map.permission :view_messages, {:boards => [:index, :show], :messages => [:show]}, :public => true
    map.permission :add_messages, {:messages => [:new, :create, :reply, :quote]}
    map.permission :edit_messages, {:messages => [:edit, :update]}, :require => :member
    map.permission :edit_own_messages, {:messages => [:edit, :update]}, :require => :loggedin
    map.permission :delete_messages, {:messages => :destroy}, :require => :member
    map.permission :delete_own_messages, {:messages => :destroy}, :require => :loggedin
  end

  map.project_module :calendar do |map|
    map.permission :view_calendar, :'issues/calendars' => [:index]
  end

  map.project_module :activity

  map.project_module :timelines do |map|
    map.permission :manage_project_configuration,
                   :require => :member
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

    map.permission :view_planning_elements,
                   {:work_packages => [:show],
                    :planning_elements => [:index, :all, :show,
                                           :recycle_bin],
                    :planning_element_journals => [:index]}
    map.permission :edit_planning_elements,
                   {:planning_elements => [:new, :create, :edit, :update],
                    :planning_element_journals => [:create]},
                   {:require => :member}
    map.permission :move_planning_elements_to_trash,
                   {:planning_elements => [:confirm_move_to_trash,
                                           :move_to_trash, :restore,
                                           :restore_all, :recycle_bin,
                                           :confirm_restore_all]},
                   {:require => :member}
    map.permission :delete_planning_elements,
                   {:planning_elements => [:confirm_destroy, :destroy,
                                           :destroy_all,
                                           :confirm_destroy_all]},
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
  menu.push :home, :home_path
  menu.push :my_page, { :controller => '/my', :action => 'page' }, :if => Proc.new { User.current.logged? }
  # projects menu will be added by Redmine::MenuManager::TopMenuHelper#render_projects_top_menu_node
  menu.push :administration, { :controller => '/admin', :action => 'projects' }, :if => Proc.new { User.current.admin? }, :last => true
  menu.push :help, Redmine::Info.help_url, :last => true, :caption => "?", :html => { :accesskey => Redmine::AccessKeys.key_for(:help) }
end

Redmine::MenuManager.map :account_menu do |menu|
  menu.push :my_account, { :controller => '/my', :action => 'account' }, :if => Proc.new { User.current.logged? }
  menu.push :logout, :signout_path, :if => Proc.new { User.current.logged? }
end

Redmine::MenuManager.map :application_menu do |menu|
  # Empty
end

Redmine::MenuManager.map :my_menu do |menu|
  menu.push :account, {:controller => '/my', :action => 'account'}, :caption => :label_my_account
  menu.push :password, {:controller => '/my', :action => 'password'}, :caption => :button_change_password, :if => Proc.new { User.current.change_password_allowed? }
  menu.push :delete_account, :deletion_info_path,
                             :caption => I18n.t('account.delete'),
                             :param => :user_id,
                             :if => Proc.new { Setting.users_deletable_by_self? }
end

Redmine::MenuManager.map :admin_menu do |menu|
  menu.push :projects, {:controller => '/admin', :action => 'projects'}, :caption => :label_project_plural
  menu.push :users, {:controller => '/users'}, :caption => :label_user_plural
  menu.push :groups, {:controller => '/groups'}, :caption => :label_group_plural
  menu.push :roles, {:controller => '/roles'}, :caption => :label_role_and_permissions
  menu.push :types, {:controller => '/types'}, :caption => :label_type_plural
  menu.push :issue_statuses, {:controller => '/issue_statuses'}, :caption => :label_work_package_status_plural,
            :html => {:class => 'issue_statuses'}
  menu.push :workflows, {:controller => '/workflows', :action => 'edit'}, :caption => Proc.new { Workflow.model_name.human }
  menu.push :custom_fields, {:controller => '/custom_fields'},  :caption => :label_custom_field_plural,
            :html => {:class => 'custom_fields'}
  menu.push :enumerations, {:controller => '/enumerations'}
  menu.push :settings, {:controller => '/settings'}
  menu.push :ldap_authentication, {:controller => '/ldap_auth_sources', :action => 'index'},
            :html => {:class => 'server_authentication'}
  menu.push :plugins, {:controller => '/admin', :action => 'plugins'}, :last => true
  menu.push :info, {:controller => '/admin', :action => 'info'}, :caption => :label_information_plural, :last => true
  menu.push :colors,
            {:controller => '/planning_element_type_colors', :action => 'index'},
            {:caption    => :'timelines.admin_menu.colors' }
  menu.push :project_types,
            {:controller => '/project_types', :action => 'index'},
            {:caption    => :'timelines.admin_menu.project_types' }
end

Redmine::MenuManager.map :project_menu do |menu|
  menu.push :overview, { :controller => '/projects', :action => 'show' }
  menu.push :activity, { :controller => '/activities', :action => 'index' }, :param => :project_id,
              :if => Proc.new { |p| p.module_enabled?("activity") }
  menu.push :roadmap, { :controller => '/versions', :action => 'index' }, :param => :project_id,
              :if => Proc.new { |p| p.shared_versions.any? }

  menu.push :issues, { :controller => '/issues', :action => 'index' }, :param => :project_id, :caption => :label_work_package_plural
  menu.push :new_issue, { :controller => '/work_packages', :action => 'new', :sti_type => 'Issue' }, :param => :project_id, :caption => :label_work_package_new, :parent => :issues,
              :html => { :accesskey => Redmine::AccessKeys.key_for(:new_issue) }
  menu.push :view_all_issues, { :controller => '/issues', :action => 'all' }, :param => :project_id, :caption => :label_work_package_view_all, :parent => :issues
  menu.push :summary_field, {:controller => '/issues/reports', :action => 'report'}, :param => :project_id, :caption => :label_workflow_summary, :parent => :issues
  menu.push :calendar, { :controller => '/issues/calendars', :action => 'index' }, :param => :project_id, :caption => :label_calendar
  menu.push :news, { :controller => '/news', :action => 'index' }, :param => :project_id, :caption => :label_news_plural
  menu.push :new_news, { :controller => '/news', :action => 'new' }, :param => :project_id, :caption => :label_news_new, :parent => :news,
              :if => Proc.new { |p| User.current.allowed_to?(:manage_news, p.project) }
  menu.push :boards, { :controller => '/boards', :action => 'index', :id => nil }, :param => :project_id,
              :if => Proc.new { |p| p.boards.any? }, :caption => :label_board_plural
  menu.push :repository, { :controller => '/repositories', :action => 'show' },
              :if => Proc.new { |p| p.repository && !p.repository.new_record? }
  menu.push :settings, { :controller => '/projects', :action => 'settings' }, :caption => :label_project_settings, :last => true


  # Project menu entries
  # * Timelines
  # ** Reports
  # ** Associations a.k.a. Dependencies
  # ** Reportings
  # ** Planning Elemnts
  # ** Papierkorb

  {:param => :project_id}.tap do |options|

    menu.push :timelines,
              {:controller => '/timelines', :action => 'index'},
              options.merge(:caption => :'timelines.project_menu.timelines')

    options.merge(:parent => :timelines).tap do |rep_options|

      menu.push :reports,
                {:controller => '/timelines', :action => 'index'},
                rep_options.merge(:caption => :'timelines.project_menu.reports')

      menu.push :project_associations,
                {:controller => '/project_associations', :action => 'index'},
                rep_options.merge(:caption => :'timelines.project_menu.project_associations',
                                  :if => Proc.new { |p| p.project_type.try :allows_association })

      menu.push :reportings,
                {:controller => '/reportings', :action => 'index'},
                rep_options.merge(:caption => :'timelines.project_menu.reportings')

      menu.push :planning_elements,
                {:controller => '/planning_elements', :action => 'all'},
                rep_options.merge(:caption => :'timelines.project_menu.planning_elements')

      menu.push :recycle_bin,
                {:controller => '/planning_elements', :action => 'recycle_bin'},
                rep_options.merge(:caption => :'timelines.project_menu.recycle_bin')

    end
  end
end

Redmine::Activity.map do |activity|
  activity.register :work_packages, :class_name => 'WorkPackage'
  activity.register :changesets
  activity.register :news
  activity.register :wiki_edits, :class_name => 'WikiContent', :default => false
  activity.register :messages, :default => false
  activity.register :time_entries, :default => false
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
  format.register :xml, Redmine::WikiFormatting::Xml::Formatter, Redmine::WikiFormatting::Xml::Helper
end

ActionView::Template.register_template_handler :rsb, Redmine::Views::ApiTemplateHandler
