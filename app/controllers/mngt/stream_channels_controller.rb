# frozen_string_literal: true

class Mngt::StreamChannelsController < ApplicationController
  before_action :require_login
  no_authorization_required! :index, :create, :update

  def index
    unless Mngt::Stream.configured?
      render json: []
      return
    end

    channels = Mngt::StreamChannelService.new(current_user).channels_for_user
    render json: channels
  rescue => e
    Rails.logger.error("[Mngt::Stream] channels_for_user failed: #{e.class}: #{e.message}")
    render json: [], status: :ok
  end

  def create
    return render json: { error: "forbidden" }, status: :forbidden unless current_user.admin?

    channel_id = params[:channelId].to_s.strip
    name       = params[:name].to_s.strip
    return render json: { error: "channel_id_blank" }, status: :bad_request if channel_id.blank?
    return render json: { error: "name_blank" }, status: :bad_request if name.blank?
    return render json: { error: "name_too_long" }, status: :bad_request if name.length > 80

    # Channel was already created by the frontend SDK. Add the right users as members.
    Mngt::StreamChannelService.new(current_user).add_all_users_to_team_channel(channel_id)
    render json: { channelId: channel_id, channelType: "team", name: name }
  rescue Mngt::StreamChannelService::Error => e
    Rails.logger.error("[Mngt::Stream] add_all_users_to_team_channel failed: #{e.message}")
    render json: { error: e.message }, status: :bad_gateway
  end

  def update
    name = params[:name].to_s.strip
    return render json: { error: "name_blank" }, status: :bad_request if name.blank?
    return render json: { error: "name_too_long" }, status: :bad_request if name.length > 80

    Mngt::StreamChannelService.new(current_user).rename_channel(params[:id], name)
    render json: { ok: true, name: name }
  rescue Mngt::StreamChannelService::Error => e
    Rails.logger.error("[Mngt::Stream] rename_channel failed: #{e.message}")
    render json: { error: e.message }, status: :bad_gateway
  end
end
