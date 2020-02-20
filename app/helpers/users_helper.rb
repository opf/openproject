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

module UsersHelper
  include OpenProject::FormTagHelper

  ##
  # @param selected The option to be marked as selected.
  # @param extra [Hash] A hash containing extra entries with a count for each.
  #                     For example: { random: 42 }
  def users_status_options_for_select(selected, extra: {})
    statuses = User::StatusOptions.user_statuses_with_count extra: extra

    options = statuses.map do |sym, count|
      ["#{translate_user_status(sym)} (#{count})", sym]
    end

    options_for_select options.sort, selected
  end

  def translate_user_status(status_name)
    I18n.t(status_name.to_sym, scope: :user)
  end

  # Format user status, including brute force prevention status
  def full_user_status(user, include_num_failed_logins = false)
    user_status = ''
    unless user.active?
      user_status = translate_user_status(user.status_name)
    end
    brute_force_status = ''
    if user.failed_too_many_recent_login_attempts?
      format = include_num_failed_logins ? :blocked_num_failed_logins : :blocked
      brute_force_status = I18n.t(format,
                                  count: user.failed_login_count,
                                  scope: :user)
    end

    both_statuses = user_status + brute_force_status
    if user_status.present? and brute_force_status.present?
      I18n.t(:status_user_and_brute_force,
             user: user_status,
             brute_force: brute_force_status,
             scope: :user)
    elsif not both_statuses.empty?
      both_statuses
    else
      I18n.t(:status_active)
    end
  end

  STATUS_CHANGE_ACTIONS = {
    # status, blocked    => [[button_title, button_name], ...]
    [:active, false]     => [[:lock, 'lock']],
    [:active, true]      => [[:reset_failed_logins, 'unlock'],
                             [:lock, 'lock']],
    [:locked, false]     => [[:unlock, 'unlock']],
    [:locked, true]      => [[:unlock_and_reset_failed_logins, 'unlock']],
    [:registered, false] => [[:activate, 'activate']],
    [:registered, true]  => [[:activate_and_reset_failed_logins, 'activate']],
  }

  # Create buttons to lock/unlock a user and reset failed logins
  def build_change_user_status_action(user)
    status = user.status_name.to_sym
    blocked = !!user.failed_too_many_recent_login_attempts?

    result = ''.html_safe
    (STATUS_CHANGE_ACTIONS[[status, blocked]] || []).each do |title, name|
      result << (yield I18n.t(title, scope: :user), name) + ' '.html_safe
    end
    result
  end

  ##
  # Returns the user avatar or a default image
  def user_avatar_icon
    op_icon('icon-context icon-user')
  end

  def change_user_status_buttons(user)
    build_change_user_status_action(user) do |title, name|
      submit_tag(title, name: name, class: 'button')
    end
  end

  def change_user_status_links(user)
    icons = {
      'unlock' => 'unlocked',
      'activate' => 'unlocked',
      'lock' => 'locked'
    }
    build_change_user_status_action(user) do |title, name|
      link_to title,
              change_status_user_path(user,
                                      name.to_sym => '1',
                                      back_url: request.fullpath),
              method: :post,
              class: "icon icon-#{icons[name]}"
    end
  end

  # Options for the new membership projects combo-box
  #
  # Disables projects the user is already member in
  def options_for_membership_project_select(user, projects)
    options = project_tree_options_for_select(projects, disabled: user.projects.ids.to_set)
    content_tag('option', "--- #{l(:actionview_instancetag_blank_option)} ---") + options
  end

  def user_mail_notification_options(user)
    user.valid_notification_options.map { |o| [l(o.last), o.first] }
  end
end
