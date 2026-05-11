# frozen_string_literal: true

require "net/http"
require "json"
require "openssl"
require "base64"

class Mngt::StreamChannelService
  STREAM_API_BASE = "https://chat.stream-io-api.com"

  Error = Class.new(StandardError)

  def initialize(user)
    @user       = user
    @api_key    = Mngt::Stream.api_key
    @api_secret = Mngt::Stream.api_secret
    @user_id    = "op_#{user.id}"
  end

  # Upsert the current user into Stream so they exist for DMs and member lists.
  def upsert_current_user
    entry = { id: @user_id, name: @user.name }
    entry[:image] = "/users/#{@user.id}/avatar" if @user.local_avatar_attachment.present?
    stream_post("/users", { users: { @user_id => entry } })
  rescue Error => e
    Rails.logger.warn("[Mngt::Stream] upsert_current_user failed: #{e.message}")
  end

  # Upsert ALL active OpenProject users into Stream (cached 24h per server instance).
  def upsert_all_users
    cache_key = "mngt_stream_all_users_upserted_v4"
    return if Rails.cache.exist?(cache_key)

    avatar_ids = Attachment.where(description: "avatar", container_type: "User").pluck(:container_id).to_set

    users_map = User.active.limit(200).each_with_object({}) do |u, h|
      uid   = "op_#{u.id}"
      entry = { id: uid, name: u.name }
      entry[:image] = "/users/#{u.id}/avatar" if avatar_ids.include?(u.id)
      h[uid] = entry
    end
    return if users_map.empty?

    stream_post("/users", { users: users_map })
    Rails.cache.write(cache_key, true, expires_in: 24.hours)
  rescue Error => e
    Rails.logger.warn("[Mngt::Stream] upsert_all_users failed: #{e.message}")
  end

  # Add the current user to team channels appropriate for their company.
  # Channel CREATION is handled by the frontend SDK (Stream requires WebSocket for creation).
  def ensure_default_channel
    ensure_user_in_all_team_channels
  end

  # Add the current user to every team channel they should have access to.
  # CSC users get added to ALL team channels.
  # Other users only get added to channels prefixed with their company slug.
  # Cached 7 days per user (1 day for CSC so new cross-company channels appear sooner).
  def ensure_user_in_all_team_channels
    cache_key = "mngt_stream_user_team_channels_#{@user_id}"
    return if Rails.cache.exist?(cache_key)

    response = stream_post("/channels", {
      filter_conditions: { type: "team" },
      sort: [{ field: "created_at", direction: -1 }],
      message_limit: 0,
      limit: 100
    })

    channel_ids = (response["channels"] || []).filter_map { |ch| ch.dig("channel", "id") }

    unless can_see_all?
      slug = company_slug
      channel_ids = channel_ids.select { |id| id.start_with?("#{slug}--") }
    end

    channel_ids.each do |ch_id|
      begin
        stream_post("/channels/team/#{ch_id}", { add_members: [@user_id] })
      rescue Error => e
        Rails.logger.warn("[Mngt::Stream] add #{@user_id} to #{ch_id} failed: #{e.message}")
      end
    end

    expiry = can_see_all? ? 1.day : 7.days
    Rails.cache.write(cache_key, true, expires_in: expiry)
  rescue Error => e
    Rails.logger.warn("[Mngt::Stream] ensure_user_in_all_team_channels failed: #{e.message}")
  end

  # Add the right users to a team channel that was already created via the frontend SDK.
  # Adds all users from the channel's own company + all CSC users.
  def add_all_users_to_team_channel(channel_id)
    channel_slug = Mngt::Companies.slug_from_channel_id(channel_id)

    csc_domain   = "grupomngt.com.br"
    user_ids = User.active.limit(500).select { |u|
      user_domain = u.mail.to_s.split("@").last.downcase
      user_domain == csc_domain ||
        Mngt::Companies.slug_for(u.mail) == channel_slug
    }.map { |u| "op_#{u.id}" }

    user_ids.each_slice(100) do |batch|
      begin
        stream_post("/channels/team/#{channel_id}", { add_members: batch })
      rescue Error => e
        Rails.logger.warn("[Mngt::Stream] add_members batch to #{channel_id} failed: #{e.message}")
      end
    end
  end

  # Returns all channels (team + messaging/DM) where the current user is a member.
  def channels_for_user
    body = {
      filter_conditions: { members: { "$in" => [@user_id] } },
      sort: [{ field: "last_message_at", direction: -1 }, { field: "created_at", direction: -1 }],
      message_limit: 0,
      limit: 60
    }
    response = stream_post("/channels", body)

    (response["channels"] || []).filter_map do |ch|
      meta = ch["channel"]
      next if meta.nil?

      reads  = ch["read"] || []
      unread = reads.find { |r| r.dig("user", "id") == @user_id }
                    &.fetch("unread_messages", 0) || 0

      result = {
        id:     meta["id"],
        type:   meta["type"],
        unread: unread.to_i
      }

      if meta["type"] == "messaging"
        raw_members = ch["members"] || []
        other_members = raw_members
          .reject { |m| m["user"].nil? || m.dig("user", "id") == @user_id }
          .map { |m| { id: m.dig("user", "id"), name: m.dig("user", "name").presence || m.dig("user", "id") } }
        result[:members] = other_members
        result[:name]    = meta["name"].presence ||
                           other_members.map { |m| m[:name] }.join(", ").presence ||
                           meta["id"]
      else
        result[:name] = meta["name"].presence || meta["id"]
      end

      result
    end
  rescue Error
    raise
  end

  # Rename any messaging channel the current user is a member of.
  def rename_channel(channel_id, name)
    stream_post("/channels/messaging/#{channel_id}", { data: { name: name } })
  end

  # Validate a 1-on-1 DM between the current user and target (company check only).
  # The channel must already exist in Stream (created via JS SDK by the frontend).
  def validate_dm(channel_id, target_user_id)
    validate_dm_company!(target_user_id)
    { channelId: channel_id, channelType: "messaging" }
  end

  # Validate a group DM (company check only).
  # The channel must already exist in Stream (created via JS SDK by the frontend).
  def validate_group_dm(channel_id, target_user_ids)
    target_user_ids.each { |uid| validate_dm_company!(uid) }
    { channelId: channel_id, channelType: "messaging" }
  end

  private

  def company_slug
    Mngt::Companies.slug_for(@user.mail) || "unknown"
  end

  def can_see_all?
    Mngt::Companies.can_see_all?(@user.mail)
  end

  def same_company?(other_user)
    Mngt::Companies.slug_for(@user.mail) == Mngt::Companies.slug_for(other_user.mail)
  end

  def validate_dm_company!(target_stream_user_id)
    return if can_see_all?

    target_op_id = target_stream_user_id.to_s.delete_prefix("op_").to_i
    target_user  = User.find_by(id: target_op_id)
    return unless target_user

    unless same_company?(target_user)
      raise Error, "Mensagens diretas só são permitidas entre usuários da mesma empresa"
    end
  end

  def server_token
    header  = Base64.urlsafe_encode64('{"alg":"HS256","typ":"JWT"}', padding: false)
    payload = Base64.urlsafe_encode64({ server: true }.to_json, padding: false)
    input   = "#{header}.#{payload}"
    sig     = Base64.urlsafe_encode64(
      OpenSSL::HMAC.digest("SHA256", @api_secret, input),
      padding: false
    )
    "#{input}.#{sig}"
  end

  def stream_post(path, body) = stream_request(:post, path, body)

  def stream_request(method, path, body)
    uri = URI("#{STREAM_API_BASE}#{path}")
    uri.query = URI.encode_www_form("api_key" => @api_key)

    klass = { post: Net::HTTP::Post, put: Net::HTTP::Put, patch: Net::HTTP::Patch }.fetch(method)
    request = klass.new(uri)
    request["Authorization"]    = server_token
    request["stream-auth-type"] = "jwt"
    request["Content-Type"]     = "application/json"
    request.body = body.to_json

    response = Net::HTTP.start(uri.hostname, uri.port,
                               use_ssl: true,
                               open_timeout: 5,
                               read_timeout: 10) { |http| http.request(request) }

    parsed = JSON.parse(response.body)

    unless response.is_a?(Net::HTTPSuccess)
      msg = parsed.is_a?(Hash) ? (parsed["message"] || parsed["detail"] || "HTTP #{response.code}") : "HTTP #{response.code}"
      raise Error, "Stream API error #{response.code}: #{msg}"
    end

    parsed
  rescue JSON::ParserError, Net::OpenTimeout, Net::ReadTimeout,
         Errno::ECONNREFUSED, SocketError => e
    raise Error, "Stream API unreachable: #{e.message}"
  end
end
