# frozen_string_literal: true

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

module My
  class AccessTokensController < ::ApplicationController
    include OpTurbo::ComponentStream

    before_action :require_login

    before_action :set_current_user
    before_action :set_grouped_ical_tokens, only: %i[index]
    before_action :set_ical_token, only: %i[revoke_ical_token]
    before_action :set_api_token, only: %i[revoke_api_key]

    menu_item :access_tokens

    layout "my"

    no_authorization_required! :index,
                               :dialog,
                               :generate_rss_key,
                               :revoke_rss_key,
                               :generate_api_key,
                               :remove_oauth_client_token,
                               :revoke_api_key,
                               :revoke_ical_token,
                               :revoke_ical_meeting_token

    def dialog
      @token_type = params[:token_type] || "api"
    end

    def index
      @oauth_client_tokens = OAuthClientToken.includes(:oauth_client).where(user: @user)
    end

    def remove_oauth_client_token
      token = OAuthClientToken.includes(:oauth_client).where(user: @user).find_by(id: params[:access_token_id])

      if token&.destroy
        flash[:info] = I18n.t("my_account.access_tokens.oauth_client.removed")
      else
        flash[:error] = I18n.t("my_account.access_tokens.oauth_client.failed")
      end
      redirect_to action: :index, tab: :client, status: :see_other
    end

    def generate_rss_key # rubocop:disable Metrics/AbcSize
      token = Token::RSS.create!(user: current_user)

      update_via_turbo_stream(
        component: My::AccessToken::APITokensSectionComponent.new(tokens: [token], token_type: Token::RSS)
      )
      respond_with_dialog(My::AccessToken::AccessTokenCreatedDialogComponent.new(token:))
    rescue StandardError => e
      Rails.logger.error "Failed to reset user ##{current_user.id} RSS key: #{e}"
      flash[:error] = t("my.access_token.failed_to_reset_token", error: e.message)
      redirect_to action: :index, status: :see_other
    end

    def revoke_rss_key
      current_user.rss_token.destroy
      flash[:info] = t("my.access_token.notice_rss_token_revoked")
    rescue StandardError => e
      Rails.logger.error "Failed to revoke rss token ##{current_user.id}: #{e}"
      flash[:error] = t("my.access_token.failed_to_reset_token", error: e.message)
    ensure
      redirect_to action: :index, status: :see_other
    end

    def generate_api_key
      result = call_generate_token_service

      result.on_success do |r|
        update_via_turbo_stream(component: section_to_render(r.result))

        dialog = My::AccessToken::AccessTokenCreatedDialogComponent.new(token: r.result)
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

    def revoke_api_key # rubocop:disable Metrics/AbcSize
      result = APITokens::DeleteService.new(user: current_user, model: @api_token).call

      # rubocop:disable Rails/ActionControllerFlashBeforeRender
      result.on_success do
        flash[:notice] = t("my.access_token.notice_api_token_revoked")
      end

      result.on_failure do |r|
        error = r.errors.map(&:message).join("; ")
        Rails.logger.error("Failed to revoke api token ##{current_user.id}: #{error}")
        flash[:error] = t("my.access_token.failed_to_revoke_token", error:)
      end
      # rubocop:enable Rails/ActionControllerFlashBeforeRender

      redirect_to action: :index, status: :see_other
    end

    def revoke_ical_meeting_token # rubocop:disable Metrics/AbcSize
      ical_meeting_token = current_user.ical_meeting_tokens.find(params[:access_token_id])
      result = APITokens::DeleteService.new(user: current_user, model: ical_meeting_token).call

      # rubocop:disable Rails/ActionControllerFlashBeforeRender
      result.on_success do
        flash[:notice] = t("my.access_token.revocation.token/ical_meeting.notice_success")
      end

      result.on_failure do |r|
        error = r.errors.map(&:message).join("; ")
        Rails.logger.error("Failed to revoke ical meeting token ##{current_user.id}: #{error}")
        flash[:error] = t("my.access_token.recocation.token/ical_meeting.notice_failure", error:)
      end
      # rubocop:enable Rails/ActionControllerFlashBeforeRender

      redirect_to action: :index, status: :see_other
    end

    def revoke_ical_token
      message = ical_destroy_info_message
      @ical_token.destroy
      flash[:info] = message
    rescue StandardError => e
      Rails.logger.error "Failed to revoke all ical tokens for ##{current_user.id}: #{e}"
      flash[:error] = t("my.access_token.failed_to_reset_token", error: e.message)
    ensure
      redirect_to action: :index, status: :see_other
    end

    private

    def set_current_user
      @user = User.current
    end

    helper_method :has_tokens?

    def has_tokens?
      Setting.feeds_enabled? || Setting.api_tokens_enabled? || current_user.ical_tokens.any?
    end

    def set_api_token
      @api_token = current_user.api_tokens.find(params[:access_token_id])
    end

    def set_ical_token
      @ical_token = current_user.ical_tokens.find(params[:access_token_id])
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

    def section_to_render(token)
      case token
      when Token::API
        My::AccessToken::APITokensSectionComponent.new(tokens: current_user.api_tokens, token_type: Token::API)
      when Token::ICalMeeting
        My::AccessToken::APITokensSectionComponent.new(tokens: current_user.ical_meeting_tokens, token_type: Token::ICalMeeting)
      else
        raise ArgumentError, "Unknown token type: #{token.class}"
      end
    end

    def call_generate_token_service # rubocop:disable Metrics/AbcSize
      if params[:token_api]
        APITokens::CreateService
        .new(user: current_user, model: Token::API.new)
        .call(token_name: params[:token_api][:token_name])
      elsif params[:token_ical_meeting]
        APITokens::CreateService
        .new(user: current_user, model: Token::ICalMeeting.new)
        .call(token_name: params[:token_ical_meeting][:token_name])
      else
        raise ArgumentError, "Unknown token type"
      end
    end
  end
end
