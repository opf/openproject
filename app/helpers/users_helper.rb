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

module UsersHelper
  include OpenProject::FormTagHelper
  include IconsHelper

  ##
  # @param selected The option to be marked as selected.
  # @param extra [Hash] A hash containing extra entries with a count for each.
  #                     For example: { random: 42 }
  def users_status_options_for_select(selected, extra: {})
    statuses = Users::StatusOptions.user_statuses_with_count(extra:)

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
    user_status = ""
    unless user.active?
      user_status = translate_user_status(user.status)
    end
    brute_force_status = ""
    if user.failed_too_many_recent_login_attempts?
      format = include_num_failed_logins ? :blocked_num_failed_logins : :blocked
      brute_force_status = I18n.t(format,
                                  count: user.failed_login_count,
                                  scope: :user)
    end

    both_statuses = user_status + brute_force_status
    if user_status.present? and brute_force_status.present?
      I18n.t("user.status_user_and_brute_force",
             user: user_status,
             brute_force: brute_force_status)
    elsif not both_statuses.empty?
      both_statuses
    else
      I18n.t(:status_active)
    end
  end

  STATUS_CHANGE_ACTIONS = {
    # status, blocked    => [[button_title, button_name], ...]
    [:active, false] => [[:lock, "lock"]],
    [:active, true] => [[:reset_failed_logins, "unlock"],
                        [:lock, "lock"]],
    [:locked, false] => [[:unlock, "unlock"]],
    [:locked, true] => [[:unlock_and_reset_failed_logins, "unlock"]],
    [:registered, false] => [[:activate, "activate"]],
    [:registered, true] => [[:activate_and_reset_failed_logins, "activate"]]
  }

  # Create buttons to lock/unlock a user and reset failed logins
  def build_change_user_status_action(user)
    result = "".html_safe
    iterate_user_statusses(user) do |title, name|
      result << ((yield title, name) + " ") # rubocop:disable Style/StringConcatenation
    end
    result
  end

  def iterate_user_statusses(user)
    status = user.status.to_sym
    blocked = !!user.failed_too_many_recent_login_attempts?

    (STATUS_CHANGE_ACTIONS[[status, blocked]] || []).each do |title, name|
      yield I18n.t(title, scope: :user), name
    end
  end

  def change_user_status_icons
    {
      "unlock" => "unlock",
      "activate" => "unlock",
      "lock" => "lock"
    }
  end

  def change_user_status_buttons(user)
    build_change_user_status_action(user) do |title, name|
      render Primer::Beta::Button.new(name:, type: :submit, title:) do |button|
        button.with_leading_visual_icon(icon: change_user_status_icons[name])
        title
      end
    end
  end

  def change_user_status_links(user)
    build_change_user_status_action(user) do |title, name|
      render Primer::Beta::Button.new(tag: :a,
                                      scheme: :link,
                                      title:,
                                      href: change_status_user_path(user,
                                                                    name.to_sym => "1",
                                                                    back_url: request.fullpath),
                                      data: { method: :post }) do |button|
        button.with_leading_visual_icon(icon: change_user_status_icons[name])
        title
      end
    end
  end

  def user_name(user)
    user ? user.name : I18n.t("user.deleted")
  end

  def allowed_management_user_profile_path(user)
    if User.current.allowed_globally?(:manage_user)
      edit_user_path(user)
    else
      user_path(user)
    end
  end

  def can_users_have_auth_source?
    LdapAuthSource.any? && !OpenProject::Configuration.disable_password_login?
  end
end
