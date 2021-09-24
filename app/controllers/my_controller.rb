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
# See COPYRIGHT and LICENSE files for more details.
#++

class MyController < ApplicationController
  include PasswordConfirmation
  include Accounts::UserPasswordChange
  include ActionView::Helpers::TagHelper

  layout 'my'

  helper_method :gon

  before_action :require_login
  before_action :set_current_user
  before_action :check_password_confirmation, only: %i[update_account]

  menu_item :account,             only: [:account]
  menu_item :settings,            only: [:settings]
  menu_item :password,            only: [:password]
  menu_item :access_token,        only: [:access_token]
  menu_item :notifications,       only: [:notifications]
  menu_item :reminders,           only: [:reminders]

  def account; end

  def update_account
    write_settings

    # If mail changed, expire all other sessions
    if @user.previous_changes['mail'] && ::Sessions::DropOtherSessionsService.call(@user, session)
      flash[:info] = "#{flash[:notice]} #{t(:notice_account_other_session_expired)}"
      flash.delete :notice
    end
  end

  def settings; end

  def update_settings
    write_settings
  end

  # Manage user's password
  def password
    @username = @user.login
    redirect_if_password_change_not_allowed_for(@user)
  end

  # When making changes here, also check AccountController.change_password
  def change_password
    change_password_flow(user: @user, params: params, update_legacy: false) do
      redirect_to action: 'password'
    end
  end

  # Administer access tokens
  def access_token; end

  # Configure user's in app notifications
  def notifications
    render html: '',
           layout: 'angular/angular',
           locals: {
             menu_name: :my_menu,
             page_title: [I18n.t(:label_my_account), I18n.t('js.notifications.settings.title')]
           }
  end

  # Configure user's mail reminders
  def reminders
    render html: '',
           layout: 'angular/angular',
           locals: { menu_name: :my_menu }
  end

  # Create a new feeds key
  def generate_rss_key
    token = Token::RSS.create!(user: current_user)
    flash[:info] = [
      # rubocop:disable Rails/OutputSafety
      t('my.access_token.notice_reset_token', type: 'RSS').html_safe,
      # rubocop:enable Rails/OutputSafety
      content_tag(:strong, token.plain_value),
      t('my.access_token.token_value_warning')
    ]
  rescue StandardError => e
    Rails.logger.error "Failed to reset user ##{current_user.id} RSS key: #{e}"
    flash[:error] = t('my.access_token.failed_to_reset_token', error: e.message)
  ensure
    redirect_to action: 'access_token'
  end

  # Create a new API key
  def generate_api_key
    token = Token::API.create!(user: current_user)
    flash[:info] = [
      # rubocop:disable Rails/OutputSafety
      t('my.access_token.notice_reset_token', type: 'API').html_safe,
      # rubocop:enable Rails/OutputSafety
      content_tag(:strong, token.plain_value),
      t('my.access_token.token_value_warning')
    ]
  rescue StandardError => e
    Rails.logger.error "Failed to reset user ##{current_user.id} API key: #{e}"
    flash[:error] = t('my.access_token.failed_to_reset_token', error: e.message)
  ensure
    redirect_to action: 'access_token'
  end

  def default_breadcrumb
    I18n.t(:label_my_account)
  end

  def show_local_breadcrumb
    false
  end

  private

  def redirect_if_password_change_not_allowed_for(user)
    unless user.change_password_allowed?
      flash[:error] = I18n.t(:notice_can_t_change_password)
      redirect_to action: 'account'
      return true
    end
    false
  end

  def write_settings
    user_params = permitted_params.my_account_settings

    result = Users::UpdateService
             .new(user: current_user, model: current_user)
             .call(user_params.to_h)

    if result&.success
      flash[:notice] = t(:notice_account_updated)
    else
      errors = result ? result.errors.full_messages.join("\n") : ''
      flash[:error] = [t(:notice_account_update_failed)]
      flash[:error] << errors
    end

    redirect_back(fallback_location: my_account_path)
  end

  helper_method :has_tokens?

  def has_tokens?
    Setting.feeds_enabled? || Setting.rest_api_enabled?
  end

  def set_current_user
    @user = current_user
  end

  def get_current_layout
    @user.pref[:my_page_layout] || DEFAULT_LAYOUT.dup
  end
end
