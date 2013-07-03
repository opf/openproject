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

module UsersHelper
  def users_status_options_for_select(selected)
    user_count_by_status = User.count(:group => 'status').to_hash
    statuses = User::STATUSES.reject{|n,i| n == :builtin}.map do |name, index|
      ["#{translate_user_status(name.to_s)} (#{user_count_by_status[index].to_i})",
       index]
    end
    options_for_select([[I18n.t(:label_all), '']] + statuses, selected)
  end

  def translate_user_status(status_name)
    I18n.t(('status_' + status_name).to_sym)
  end

  # Format user status, including brute force prevention status
  def full_user_status(user)
    user_status = ''
    unless [User::STATUSES[:active], User::STATUSES[:builtin]].include?(user.status)
      user_status = translate_user_status(user.status_name)
    end
    brute_force_status = ''
    if user.failed_too_many_recent_login_attempts?
      brute_force_status = I18n.t(:blocked_num_failed_logins,
                                  :count => user.failed_login_count,
                                  :scope => [:user, :brute_force_status])
    end

    both_statuses = user_status + brute_force_status
    if user_status.present? and brute_force_status.present?
      I18n.t(:status_user_and_brute_force,
             :user => user_status,
             :brute_force => brute_force_status,
             :scope => :user)
    elsif not both_statuses.empty?
      both_statuses
    else
      I18n.t(:status_active)
    end
  end

  # Create buttons to lock/unlock a user and reset failed logins
  def change_user_status_buttons(user)
    status = user.status_name
    blocked = user.failed_too_many_recent_login_attempts?
    result = ''.html_safe
    if status == :active
      if blocked
        result << submit_tag(I18n.t(:reset_failed_logins, :scope => :user),
                             :name => 'unlock')
      end
      result << submit_tag(I18n.t(:lock, :scope => :user), :name => 'lock')
    else
      if status == :locked
        title = blocked ? :unlock_and_reset_failed_logins : :unlock
        result << submit_tag(I18n.t(title, :scope => :user), :name => 'unlock')
      elsif status == :registered
        title = blocked ? :activate_and_reset_failed_logins : :activate
        result << submit_tag(I18n.t(title, :scope => :user), :name => 'activate')
      end
    end
    result
  end

  # Options for the new membership projects combo-box
  def options_for_membership_project_select(user, projects)
    options = content_tag('option', "--- #{l(:actionview_instancetag_blank_option)} ---")
    options << project_tree_options_for_select(projects) do |p|
      {:disabled => (user.projects.include?(p))}
    end
    options
  end

  def user_mail_notification_options(user)
    user.valid_notification_options.collect {|o| [l(o.last), o.first]}
  end

  def change_status_link(user)
    url = {:controller => '/users', :action => 'update', :id => user, :page => params[:page], :status => params[:status], :tab => nil}

    if user.locked?
      link_to l(:button_unlock), url.merge(:user => {:status => User::STATUSES[:active]}), :method => :put, :class => 'icon icon-unlock'
    elsif user.registered?
      link_to l(:button_activate), url.merge(:user => {:status => User::STATUSES[:active]}), :method => :put, :class => 'icon icon-unlock'
    elsif user != User.current
      link_to l(:button_lock), url.merge(:user => {:status => User::STATUSES[:locked]}), :method => :put, :class => 'icon icon-lock'
    end
  end

  def user_settings_tabs
    tabs = [{:name => 'general', :partial => 'users/general', :label => :label_general},
            {:name => 'memberships', :partial => 'users/memberships', :label => :label_project_plural}
            ]
    if Group.all.any?
      tabs.insert 1, {:name => 'groups', :partial => 'users/groups', :label => :label_group_plural}
    end
    tabs
  end
end
