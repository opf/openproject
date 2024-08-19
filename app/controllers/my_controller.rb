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

class MyController < ApplicationController
  include PasswordConfirmation
  include Accounts::UserPasswordChange
  include ActionView::Helpers::TagHelper
  include OpTurbo::ComponentStream
  include FlashMessagesOutputSafetyHelper

  layout "my"

  before_action :require_login
  before_action :set_current_user
  before_action :check_password_confirmation, only: %i[update_account]
  before_action :set_grouped_ical_tokens, only: %i[access_token]
  before_action :set_ical_token, only: %i[revoke_ical_token]
  before_action :set_api_token, only: %i[revoke_api_key]

  no_authorization_required! :account,
                             :update_account,
                             :settings,
                             :update_settings,
                             :password,
                             :change_password,
                             :access_token,
                             :delete_storage_token,
                             :notifications,
                             :reminders,
                             :generate_rss_key,
                             :revoke_rss_key,
                             :generate_api_key,
                             :revoke_api_key,
                             :revoke_ical_token

  menu_item :account, only: [:account]
  menu_item :settings, only: [:settings]
  menu_item :password, only: [:password]
  menu_item :access_token, only: [:access_token]
  menu_item :notifications, only: [:notifications]
  menu_item :reminders, only: [:reminders]

  def account; end

  def update_account
    write_settings
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
    change_password_flow(user: @user, params:, update_legacy: false) do
      redirect_to action: "password"
    end
  end

  # Administer access tokens
  def access_token
    @storage_tokens = OAuthClientToken
                        .preload(:oauth_client)
                        .joins(:oauth_client)
                        .where(user: @user, oauth_client: { integration_type: "Storages::Storage" })
  end

  def delete_storage_token
    token = OAuthClientToken
              .preload(:oauth_client)
              .joins(:oauth_client)
              .where(user: @user, oauth_client: { integration_type: "Storages::Storage" }).find_by(id: params[:id])

    if token&.destroy
      flash[:info] = I18n.t("my_account.access_tokens.storages.removed")
    else
      flash[:error] = I18n.t("my_account.access_tokens.storages.failed")
    end
    redirect_to action: :access_token
  end

  # Configure user's in app notifications
  def notifications; end

  # Configure user's mail reminders
  def reminders; end

  # Create a new feeds key
  def generate_rss_key
    token = Token::RSS.create!(user: current_user)
    flash[:info] = [
      t("my.access_token.notice_reset_token", type: "RSS").html_safe,
      content_tag(:strong, token.plain_value),
      t("my.access_token.token_value_warning")
    ]
  rescue StandardError => e
    Rails.logger.error "Failed to reset user ##{current_user.id} RSS key: #{e}"
    flash[:error] = t("my.access_token.failed_to_reset_token", error: e.message)
  ensure
    redirect_to action: "access_token"
  end

  def revoke_rss_key
    current_user.rss_token.destroy
    flash[:info] = t("my.access_token.notice_rss_token_revoked")
  rescue StandardError => e
    Rails.logger.error "Failed to revoke rss token ##{current_user.id}: #{e}"
    flash[:error] = t("my.access_token.failed_to_reset_token", error: e.message)
  ensure
    redirect_to action: "access_token"
  end

  # rubocop:disable Metrics/AbcSize
  def generate_api_key
    result = APITokens::CreateService.new(user: current_user).call(token_name: params[:token_api][:token_name])

    result.on_success do |r|
      update_via_turbo_stream(
        component: My::AccessToken::APITokensSectionComponent.new(api_tokens: @user.api_tokens)
      )

      dialog = My::AccessToken::AccessTokenCreatedDialogComponent.new(token_value: r.result.plain_value)
      modify_via_turbo_stream(component: dialog, action: :dialog, status: :ok)
    end

    result.on_failure do |r|
      update_via_turbo_stream(
        component: My::AccessToken::NewAccessTokenFormComponent.new(token: r.result),
        status: :bad_request
      )
    end

    respond_with_turbo_streams
  end

  # rubocop:enable Metrics/AbcSize

  # rubocop:disable Metrics/AbcSize
  def revoke_api_key
    result = APITokens::DeleteService.new(user: current_user, model: @api_token).call

    # rubocop:disable Rails/ActionControllerFlashBeforeRender
    result.on_success do
      flash[:primer_banner] = { message: t("my.access_token.notice_api_token_revoked") }
    end

    result.on_failure do |r|
      error = r.errors.map(&:message).join("; ")
      Rails.logger.error("Failed to revoke api token ##{current_user.id}: #{error}")
      flash[:primer_banner] = { message: t("my.access_token.failed_to_revoke_token", error:), scheme: :danger }
    end
    # rubocop:enable Rails/ActionControllerFlashBeforeRender

    redirect_to action: "access_token"
  end

  # rubocop:enable Metrics/AbcSize

  def revoke_ical_token
    message = ical_destroy_info_message
    @ical_token.destroy
    flash[:info] = message
  rescue StandardError => e
    Rails.logger.error "Failed to revoke all ical tokens for ##{current_user.id}: #{e}"
    flash[:error] = t("my.access_token.failed_to_reset_token", error: e.message)
  ensure
    redirect_to action: "access_token"
  end

  private

  def default_breadcrumb
    I18n.t(:label_my_account)
  end

  def show_local_breadcrumb
    false
  end

  def redirect_if_password_change_not_allowed_for(user)
    unless user.change_password_allowed?
      flash[:error] = I18n.t(:notice_can_t_change_password)
      redirect_to action: "account"
      return true
    end
    false
  end

  def write_settings
    result = Users::UpdateService
               .new(user: current_user, model: current_user)
               .call(user_params)

    if result&.success
      flash[:notice] = notice_account_updated
      handle_email_changes
    else
      flash[:error] = error_account_update_failed(result)
    end

    redirect_back(fallback_location: my_account_path)
  end

  helper_method :has_tokens?

  def handle_email_changes
    # If mail changed, expire all other sessions
    if @user.previous_changes['mail']
      Users::DropTokensService.new(current_user: @user).call!
      Sessions::DropOtherSessionsService.call!(@user, session)

      flash[:info] = "#{flash[:notice]} #{t(:notice_account_other_session_expired)}"
      flash.delete :notice
    end
  end

  def has_tokens?
    Setting.feeds_enabled? || Setting.rest_api_enabled? || current_user.ical_tokens.any?
  end

  def user_params
    permitted_params.my_account_settings.to_h
  end

  def notice_account_updated
    OpenProject::LocaleHelper.with_locale_for(current_user) do
      t(:notice_account_updated)
    end
  end

  def error_account_update_failed(result)
    errors = result ? result.errors.full_messages.join("\n") : ""
    [t(:notice_account_update_failed), errors]
  end

  def set_current_user
    @user = current_user
  end

  def get_current_layout
    @user.pref[:my_page_layout] || DEFAULT_LAYOUT.dup
  end

  def set_api_token
    @api_token = current_user.api_tokens.find(params[:token_id])
  end

  def set_ical_token
    @ical_token = current_user.ical_tokens.find(params[:id])
  end

  def set_grouped_ical_tokens
    @ical_tokens_grouped_by_query = current_user.ical_tokens
                                                .joins(ical_token_query_assignment: { query: :project })
                                                .select("tokens.*, ical_token_query_assignments.query_id")
                                                .group_by(&:query_id)
  end

  def ical_destroy_info_message
    t(
      "my.access_token.notice_ical_token_revoked",
      token_name: @ical_token.ical_token_query_assignment.name,
      calendar_name: @ical_token.query.name,
      project_name: @ical_token.query.project.name
    )
  end
end
