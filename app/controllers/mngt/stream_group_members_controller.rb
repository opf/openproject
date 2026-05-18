# frozen_string_literal: true

class Mngt::StreamGroupMembersController < ApplicationController
  before_action :require_login
  no_authorization_required! :create

  def create
    channel_id = params[:channelId].to_s.presence
    user_ids   = Array(params[:userIds]).map(&:to_s).select(&:present?)

    return render json: { error: "no_channel_id" }, status: :bad_request if channel_id.blank?
    return render json: { error: "no_users" }, status: :bad_request if user_ids.empty?

    raw_ids = user_ids.map { |uid| uid.delete_prefix("op_").to_i }
    found   = User.active.where(id: raw_ids).count
    return render json: { error: "user_not_found" }, status: :not_found unless found == raw_ids.uniq.count

    Mngt::StreamChannelService.new(current_user).add_members_to_group(channel_id, user_ids)
    render json: { ok: true }
  rescue Mngt::StreamChannelService::Error => e
    Rails.logger.error("[Mngt::Stream] add_members_to_group failed: #{e.message}")
    render json: { error: e.message }, status: :bad_gateway
  end
end
