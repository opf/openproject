#-- encoding: UTF-8
#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2021 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'redmine/menu_manager'

Redmine::MenuManager.map :top_menu do |menu|
  # projects menu will be added by
  # Redmine::MenuManager::TopMenuHelper#render_projects_top_menu_node
  menu.push :projects,
            { controller: '/projects', project_id: nil, action: 'index' },
            context: :modules,
            caption: I18n.t('label_projects_menu'),
            if: Proc.new {
              (User.current.logged? || !Setting.login_required?)
            }
  menu.push :work_packages,
            { controller: '/work_packages', project_id: nil, state: nil, action: 'index' },
            context: :modules,
            caption: I18n.t('label_work_package_plural'),
            if: Proc.new {
              (User.current.logged? || !Setting.login_required?) &&
                User.current.allowed_to?(:view_work_packages, nil, global: true)
            }
  menu.push :news,
            { controller: '/news', project_id: nil, action: 'index' },
            context: :modules,
            caption: I18n.t('label_news_plural'),
            if: Proc.new {
              (User.current.logged? || !Setting.login_required?) &&
                User.current.allowed_to?(:view_news, nil, global: true)
            }
  menu.push :help,
            OpenProject::Static::Links.help_link,
            last: true,
            caption: '',
            icon: 'icon5 icon-help',
            html: { accesskey: OpenProject::AccessKeys.key_for(:help),
                    title: I18n.t('label_help'),
                    class: 'top-menu-help',
                    target: '_blank' }
end

Redmine::MenuManager.map :quick_add_menu do |menu|
  menu.push :new_project,
            { controller: '/projects', action: :new },
            caption: Project.model_name.human,
            icon: "icon-add icon3",
            html: {
              aria: { label: I18n.t(:label_project_new) },
              title: I18n.t(:label_project_new)
            },
            if: Proc.new { User.current.allowed_to_globally?(:add_project) }

  menu.push :invite_user,
            '#',
            caption: :label_invite_user,
            icon: 'icon3 icon-user-plus',
            html: {
              'invite-user-entry': 'invite-user-entry'
            }
end

Redmine::MenuManager.map :account_menu do |menu|
  menu.push :my_page,
            :my_page_path,
            caption: I18n.t('js.my_page.label'),
            if: Proc.new { User.current.logged? }
  menu.push :my_account,
            { controller: '/my', action: 'account' },
            if: Proc.new { User.current.logged? }
  menu.push :administration,
            { controller: '/admin', action: 'index' },
            if: Proc.new { User.current.allowed_to_globally?(:manage_placeholder_user) || User.current.allowed_to_globally?(:manage_user) }
  menu.push :logout,
            :signout_path,
            if: Proc.new { User.current.logged? }
end

Redmine::MenuManager.map :application_menu do |menu|
  menu.push :work_packages_query_select,
            { controller: '/work_packages', action: 'index' },
            parent: :work_packages,
            partial: 'work_packages/menu_query_select',
            last: true
end

Redmine::MenuManager.map :my_menu do |menu|
  menu_push = menu.push :account,
                        { controller: '/my', action: 'account' },
                        caption: :label_profile,
                        icon: 'icon2 icon-user'
  menu_push
  menu.push :settings,
            { controller: '/my', action: 'settings' },
            caption: :label_setting_plural,
            icon: 'icon2 icon-settings2'
  menu.push :password,
            { controller: '/my', action: 'password' },
            caption: :button_change_password,
            if: Proc.new { User.current.change_password_allowed? },
            icon: 'icon2 icon-locked'
  menu.push :access_token,
            { controller: '/my', action: 'access_token' },
            caption: I18n.t('my_account.access_tokens.access_token'),
            icon: 'icon2 icon-key'
  menu.push :mail_notifications,
            { controller: '/my', action: 'mail_notifications' },
            caption: I18n.t('activerecord.attributes.user.mail_notification'),
            icon: 'icon2 icon-news'

  menu.push :delete_account, :delete_my_account_info_path,
            caption: I18n.t('account.delete'),
            param: :user_id,
            if: Proc.new { Setting.users_deletable_by_self? },
            last: :delete_account,
            icon: 'icon2 icon-delete'
end

Redmine::MenuManager.map :admin_menu do |menu|
  menu.push :admin_overview,
            { controller: '/admin', action: :index },
            if: Proc.new { User.current.admin? },
            caption: :label_overview,
            icon: 'icon2 icon-home',
            first: true

  menu.push :users,
            { controller: '/users' },
            if: Proc.new { !User.current.admin? && User.current.allowed_to_globally?(:manage_user) },
            caption: :label_user_plural,
            icon: 'icon2 icon-group'

  menu.push :placeholder_users,
            { controller: '/placeholder_users' },
            if: Proc.new { !User.current.admin? && User.current.allowed_to_globally?(:manage_placeholder_user) },
            caption: :label_placeholder_user_plural,
            icon: 'icon2 icon-group'

  menu.push :users_and_permissions,
            { controller: '/users' },
            if: Proc.new { User.current.admin? },
            caption: :label_user_and_permission,
            icon: 'icon2 icon-group'

  menu.push :user_settings,
            { controller: '/admin/settings/users_settings', action: :show },
            if: Proc.new { User.current.admin? },
            caption: :label_setting_plural,
            parent: :users_and_permissions

  menu.push :users,
            { controller: '/users' },
            if: Proc.new { User.current.admin? },
            caption: :label_user_plural,
            parent: :users_and_permissions

  menu.push :placeholder_users,
            { controller: '/placeholder_users' },
            if: Proc.new { User.current.admin? },
            caption: :label_placeholder_user_plural,
            parent: :users_and_permissions

  menu.push :groups,
            { controller: '/groups' },
            if: Proc.new { User.current.admin? },
            caption: :label_group_plural,
            parent: :users_and_permissions

  menu.push :roles,
            { controller: '/roles' },
            if: Proc.new { User.current.admin? },
            caption: :label_role_and_permissions,
            parent: :users_and_permissions

  menu.push :user_avatars,
            { controller: '/admin/settings', action: 'show_plugin', id: :openproject_avatars },
            if: Proc.new { User.current.admin? },
            caption: :label_avatar_plural,
            parent: :users_and_permissions

  menu.push :admin_work_packages,
            { controller: '/admin/settings/work_packages_settings', action: :show },
            if: Proc.new { User.current.admin? },
            caption: :label_work_package_plural,
            icon: 'icon2 icon-view-timeline'

  menu.push :work_packages_setting,
            { controller: '/admin/settings/work_packages_settings', action: :show },
            if: Proc.new { User.current.admin? },
            caption: :label_setting_plural,
            parent: :admin_work_packages

  menu.push :types,
            { controller: '/types' },
            if: Proc.new { User.current.admin? },
            caption: :label_type_plural,
            parent: :admin_work_packages

  menu.push :statuses,
            { controller: '/statuses' },
            if: Proc.new { User.current.admin? },
            caption: :label_status,
            parent: :admin_work_packages,
            html: { class: 'statuses' }

  menu.push :workflows,
            { controller: '/workflows', action: 'edit' },
            if: Proc.new { User.current.admin? },
            caption: Proc.new { Workflow.model_name.human },
            parent: :admin_work_packages

  menu.push :custom_fields,
            { controller: '/custom_fields' },
            if: Proc.new { User.current.admin? },
            caption: :label_custom_field_plural,
            icon: 'icon2 icon-custom-fields',
            html: { class: 'custom_fields' }

  menu.push :custom_actions,
            { controller: '/custom_actions' },
            if: Proc.new { User.current.admin? },
            caption: :'custom_actions.plural',
            parent: :admin_work_packages

  menu.push :attribute_help_texts,
            { controller: '/attribute_help_texts' },
            caption: :'attribute_help_texts.label_plural',
            icon: 'icon2 icon-help2',
            if: Proc.new {
              User.current.admin? && EnterpriseToken.allows_to?(:attribute_help_texts)
            }

  menu.push :enumerations,
            { controller: '/enumerations' },
            if: Proc.new { User.current.admin? },
            icon: 'icon2 icon-enumerations'

  menu.push :settings,
            { controller: '/admin/settings/general_settings', action: :show },
            if: Proc.new { User.current.admin? },
            caption: :label_system_settings,
            icon: 'icon2 icon-settings2'

  SettingsHelper.system_settings_tabs.each do |node|
    menu.push :"settings_#{node[:name]}",
              { controller: node[:controller], action: :show },
              caption: node[:label],
              if: Proc.new { User.current.admin? },
              parent: :settings
  end

  menu.push :email,
            { controller: '/admin/settings/mail_notifications_settings', action: :show },
            if: Proc.new { User.current.admin? },
            caption: :'attributes.mail',
            icon: 'icon2 icon-mail1'

  menu.push :mail_notifications,
            { controller: '/admin/settings/mail_notifications_settings', action: :show },
            if: Proc.new { User.current.admin? },
            caption: :'activerecord.attributes.user.mail_notification',
            parent: :email

  menu.push :incoming_mails,
            { controller: '/admin/settings/incoming_mails_settings', action: :show },
            if: Proc.new { User.current.admin? },
            caption: :label_incoming_emails,
            parent: :email

  menu.push :authentication,
            { controller: '/admin/settings/authentication_settings', action: :show },
            if: Proc.new { User.current.admin? },
            caption: :label_authentication,
            icon: 'icon2 icon-two-factor-authentication'

  menu.push :authentication_settings,
            { controller: '/admin/settings/authentication_settings', action: :show },
            if: Proc.new { User.current.admin? },
            caption: :label_setting_plural,
            parent: :authentication

  menu.push :ldap_authentication,
            { controller: '/ldap_auth_sources', action: 'index' },
            if: Proc.new { User.current.admin? },
            parent: :authentication,
            html: { class: 'server_authentication' },
            last: true,
            if: proc { !OpenProject::Configuration.disable_password_login? }

  menu.push :oauth_applications,
            { controller: '/oauth/applications', action: 'index' },
            if: Proc.new { User.current.admin? },
            parent: :authentication,
            caption: :'oauth.application.plural',
            html: { class: 'oauth_applications' }

  menu.push :announcements,
            { controller: '/announcements', action: 'edit' },
            if: Proc.new { User.current.admin? },
            caption: :label_announcement,
            icon: 'icon2 icon-news'

  menu.push :plugins,
            { controller: '/admin', action: 'plugins' },
            if: Proc.new { User.current.admin? },
            last: true,
            icon: 'icon2 icon-plugins'

  menu.push :info,
            { controller: '/admin', action: 'info' },
            if: Proc.new { User.current.admin? },
            caption: :label_information_plural,
            last: true,
            icon: 'icon2 icon-info1'

  menu.push :custom_style,
            { controller: '/custom_styles', action: :show },
            if: Proc.new { User.current.admin? },
            caption: :label_custom_style,
            icon: 'icon2 icon-design'

  menu.push :colors,
            { controller: '/colors', action: 'index' },
            if: Proc.new { User.current.admin? },
            caption: :'timelines.admin_menu.colors',
            icon: 'icon2 icon-status'

  menu.push :enterprise,
            { controller: '/enterprises', action: :show },
            caption: :label_enterprise_edition,
            icon: 'icon2 icon-headset',
            if: proc { User.current.admin? && OpenProject::Configuration.ee_manager_visible? }

  menu.push :admin_costs,
            { controller: '/admin/settings', action: 'show_plugin', id: :costs },
            if: Proc.new { User.current.admin? },
            caption: :project_module_costs,
            icon: 'icon2 icon-budget'

  menu.push :costs_setting,
            { controller: '/admin/settings', action: 'show_plugin', id: :costs },
            if: Proc.new { User.current.admin? },
            caption: :label_setting_plural,
            parent: :admin_costs

  menu.push :admin_backlogs,
            { controller: '/backlogs_settings', action: :show },
            if: Proc.new { User.current.admin? },
            caption: :label_backlogs,
            icon: 'icon2 icon-backlogs'

  menu.push :backlogs_settings,
            { controller: '/backlogs_settings', action: :show },
            if: Proc.new { User.current.admin? },
            caption: :label_setting_plural,
            parent: :admin_backlogs
end

Redmine::MenuManager.map :project_menu do |menu|
  menu.push :activity,
            { controller: '/activities', action: 'index' },
            param: :project_id,
            if: Proc.new { |p| p.module_enabled?('activity') },
            icon: 'icon2 icon-checkmark'

  menu.push :roadmap,
            { controller: '/versions', action: 'index' },
            param: :project_id,
            if: Proc.new { |p| p.shared_versions.any? },
            icon: 'icon2 icon-roadmap'

  menu.push :work_packages,
            { controller: '/work_packages', action: 'index' },
            param: :project_id,
            caption: :label_work_package_plural,
            icon: 'icon2 icon-view-timeline',
            html: {
              id: 'main-menu-work-packages',
              'wp-query-menu': 'wp-query-menu'
            }

  menu.push :work_packages_query_select,
            { controller: '/work_packages', action: 'index' },
            param: :project_id,
            parent: :work_packages,
            partial: 'work_packages/menu_query_select',
            last: true,
            caption: :label_all_open_wps

  menu.push :calendar,
            { controller: '/work_packages/calendars', action: 'index' },
            param: :project_id,
            caption: :label_calendar,
            icon: 'icon2 icon-calendar'

  menu.push :news,
            { controller: '/news', action: 'index' },
            param: :project_id,
            caption: :label_news_plural,
            icon: 'icon2 icon-news'

  menu.push :forums,
            { controller: '/forums', action: 'index', id: nil },
            param: :project_id,
            caption: :label_forum_plural,
            icon: 'icon2 icon-ticket-note'

  menu.push :repository,
            { controller: '/repositories', action: :show },
            param: :project_id,
            if: Proc.new { |p| p.repository && !p.repository.new_record? },
            icon: 'icon2 icon-folder-open'

  # Wiki menu items are added by WikiMenuItemHelper

  menu.push :members,
            { controller: '/members', action: 'index' },
            param: :project_id,
            caption: :label_member_plural,
            before: :settings,
            icon: 'icon2 icon-group'

  menu.push :settings,
            { controller: '/project_settings/generic', action: :show },
            caption: :label_project_settings,
            last: true,
            icon: 'icon2 icon-settings2',
            allow_deeplink: true

  ProjectSettingsHelper.project_settings_tabs.each do |node|
    menu.push :"settings_#{node[:name]}",
              node[:action],
              caption: node[:label],
              parent: :settings,
              last: node[:last],
              if: node[:if]
  end
end
