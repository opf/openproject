# frozen_string_literal: true

class Mngt::StreamTokenController < ApplicationController
  before_action :require_login
  no_authorization_required! :show

  def show
    unless Mngt::Stream.configured?
      render json: { error: "not_configured" }, status: :not_found
      return
    end

    service      = Mngt::StreamService.new(current_user)
    channel_svc  = Mngt::StreamChannelService.new(current_user)

    # Provision user and defaults synchronously (cached after first run).
    channel_svc.upsert_current_user
    channel_svc.upsert_all_users
    channel_svc.ensure_default_channel

    render json: {
      token:  service.user_token,
      userId: service.user_id,
      apiKey: Mngt::Stream.api_key,
      user:   service.user_data
    }
  rescue => e
    Rails.logger.error("[Mngt::Stream] token generation failed: #{e.message}")
    render json: { error: "service_error" }, status: :unprocessable_entity
  end
end
