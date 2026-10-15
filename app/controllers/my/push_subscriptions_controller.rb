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
  class PushSubscriptionsController < ::ApplicationController
    include OpTurbo::ComponentStream

    before_action :require_login
    guard_feature_flag :progressive_web_app
    before_action :require_web_push
    no_authorization_required! :create, :destroy

    def create
      result = subscribe_service.call(endpoint: params[:push_endpoint].to_s, resume: resume?)

      if result.failure?
        render json: { errors: result.errors.full_messages }, status: :unprocessable_entity
      elsif resume?
        head :no_content
      else
        render_devices
      end
    end

    def destroy
      result = ::PushSubscriptions::DeleteService.new(model: own_subscription, user: current_user).call

      respond_to do |format|
        format.turbo_stream { render_destroy_streams(result) }
        format.html { redirect_after_destroy(result) }
      end
    end

    private

    def own_subscription
      PushSubscription.where(user: current_user).find(params.expect(:id))
    end

    def subscribe_service
      ::PushSubscriptions::SubscribeService.new(user: current_user, session_id: current_session_row_id, device:)
    end

    def device
      { browser_name: session[:browser], browser_version: session[:browser_version], platform: session[:platform] }
    end

    def resume?
      ActiveModel::Type::Boolean.new.cast(params[:resume])
    end

    def render_devices
      replace_via_turbo_stream(component: show_page_component)
      respond_with_turbo_streams
    end

    def render_destroy_streams(result)
      if result.success?
        render_revoked_flash unless params[:silent]
      else
        render_error_flash_message_via_turbo_stream(message: result.errors.full_messages.to_sentence)
      end

      render_devices
    end

    def render_revoked_flash
      render_success_flash_message_via_turbo_stream(message: I18n.t("my_account.push_notifications.revoked"))
    end

    def redirect_after_destroy(result)
      if result.success?
        flash[:notice] = I18n.t("my_account.push_notifications.revoked")
      else
        flash[:error] = result.errors.full_messages.to_sentence
      end

      redirect_to my_notifications_path(tab: "push"), status: :see_other
    end

    def require_web_push
      render_404 unless Setting.web_push_enabled?
    end

    def current_session_row_id
      Sessions::UserSession.where(session_id: session.id&.private_id).pick(:id)
    end

    def show_page_component
      My::PushSubscriptions::ShowPageComponent.new(user: current_user, current_session: session)
    end
  end
end
