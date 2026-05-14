# frozen_string_literal: true

class Mngt::StreamDmController < ApplicationController
  before_action :require_login
  no_authorization_required! :create

  def create
    user_ids   = Array(params[:userIds]).map(&:to_s)
    user_ids   = [params[:userId].to_s] if user_ids.empty? && params[:userId].present?
    channel_id = params[:channelId].to_s.presence

    return render json: { error: "no_users" }, status: :bad_request if user_ids.empty?
    return render json: { error: "no_channel_id" }, status: :bad_request if channel_id.blank?

    raw_ids = user_ids.map { |uid| uid.delete_prefix("op_").to_i }
    found   = User.active.where(id: raw_ids).count

    unless found == raw_ids.uniq.count
      render json: { error: "user_not_found" }, status: :not_found
      return
    end

    svc    = Mngt::StreamChannelService.new(current_user)
    result = if user_ids.length == 1
      svc.validate_dm(channel_id, user_ids.first)
    else
      svc.validate_group_dm(channel_id, user_ids)
    end
    render json: result
  rescue Mngt::StreamChannelService::Error => e
    Rails.logger.error("[Mngt::Stream] DM validation failed: #{e.message}")
    render json: { error: e.message }, status: :bad_gateway
  end
end
