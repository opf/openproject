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
    entry[:image] = "#{Setting.protocol}://#{Setting.host_name}/users/#{@user.id}/avatar" if @user.local_avatar_attachment.present?
    stream_post("/users", { users: { @user_id => entry } })
  rescue Error => e
    Rails.logger.warn("[Mngt::Stream] upsert_current_user failed: #{e.message}")
  end

  # Upsert ALL active OpenProject users into Stream (cached 24h per server instance).
  # Stream's /users endpoint accepts up to 100 users per request, so we batch.
  def upsert_all_users
    cache_key = "mngt_stream_all_users_upserted_v5"
    return if Rails.cache.exist?(cache_key)

    avatar_ids = Attachment.where(description: "avatar", container_type: "Principal").pluck(:container_id).to_set

    all_entries = User.active.find_each.map do |u|
      uid   = "op_#{u.id}"
      entry = { id: uid, name: u.name }
      entry[:image] = "#{Setting.protocol}://#{Setting.host_name}/users/#{u.id}/avatar" if avatar_ids.include?(u.id)
      [uid, entry]
    end
    return if all_entries.empty?

    all_entries.each_slice(100) do |batch|
      stream_post("/users", { users: batch.to_h })
    end

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
        name = ch_id.end_with?("--geral") ? "Geral" : nil
        add_to_team_channel(ch_id, channel_name: name)
      rescue Error => e
        Rails.logger.warn("[Mngt::Stream] add #{@user_id} to #{ch_id} failed: #{e.message}")
      end
    end

    expiry = can_see_all? ? 1.day : 7.days
    Rails.cache.write(cache_key, true, expires_in: expiry)
  rescue Error => e
    Rails.logger.warn("[Mngt::Stream] ensure_user_in_all_team_channels failed: #{e.message}")
  end

  # Add the current user to a specific team channel by ID.
  # Pass channel_name to auto-create the channel if it doesn't exist yet.
  def add_to_team_channel(channel_id, channel_name: nil)
    body = { add_members: [@user_id] }
    body[:data] = { name: channel_name } if channel_name
    stream_post("/channels/team/#{channel_id}", body)
  rescue Error => e
    Rails.logger.warn("[Mngt::Stream] add_to_team_channel #{channel_id} failed: #{e.message}")
  end

  # Create (or update) a team channel server-side and populate it with all eligible members.
  # Used by the provision rake task and channel auto-setup.
  def provision_team_channel(channel_id, channel_name: "Geral")
    # POST …/query with state:true is Stream's create-or-fetch endpoint (REST, no WebSocket).
    # POST …/{id} is update-only and 404s when the channel doesn't exist yet.
    stream_post("/channels/team/#{channel_id}/query", {
      state:    true,
      watch:    false,
      presence: false,
      data:     { name: channel_name, created_by_id: @user_id }
    })
    add_all_users_to_team_channel(channel_id)
  rescue Error => e
    Rails.logger.warn("[Mngt::Stream] provision_team_channel #{channel_id} failed: #{e.message}")
  end

  # Add the right users to a team channel that was already created via the frontend SDK.
  # Adds all users from the channel's own company + all CSC users.
  def add_all_users_to_team_channel(channel_id)
    channel_slug  = Mngt::Companies.slug_from_channel_id(channel_id)
    profile_slugs = Mngt::UserProfile.all.pluck(:user_id, :company_slug).to_h

    user_ids = []
    User.active.find_each do |u|
      slug = profile_slugs[u.id] || Mngt::Companies.slug_for(u.mail)
      next unless Mngt::Companies.can_see_all_by_slug?(slug) || slug == channel_slug

      user_ids << "op_#{u.id}"
    end

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

  # Add members to an existing group DM (messaging channel) server-side.
  def add_members_to_group(channel_id, user_ids)
    stream_post("/channels/messaging/#{channel_id}", { add_members: user_ids })
  end

  # Deactivate the user in Stream (called when the user is locked/deactivated).
  def deactivate_user
    stream_post("/users/#{@user_id}/deactivate", {})
  rescue Error => e
    Rails.logger.warn("[Mngt::Stream] deactivate_user failed for #{@user_id}: #{e.message}")
  end

  # Send a message to a channel as the current user.
  def send_message(channel_type, channel_id, text)
    stream_post("/channels/#{channel_type}/#{channel_id}/message", {
      message: { text:, user_id: @user_id }
    })
  end

  # Rename a channel the current user is a member of.
  def rename_channel(channel_id, name, channel_type: "messaging")
    stream_post("/channels/#{channel_type}/#{channel_id}", { data: { name: name } })
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
    Mngt::UserProfile.where(user: @user).pick(:company_slug) ||
      Mngt::Companies.slug_for(@user.mail) || "unknown"
  end

  def can_see_all?
    Mngt::Companies.can_see_all_by_slug?(company_slug)
  end

  def same_company?(other_user)
    slug_for_user(@user) == slug_for_user(other_user)
  end

  def slug_for_user(user)
    Mngt::UserProfile.where(user: user).pick(:company_slug) ||
      Mngt::Companies.slug_for(user.mail) || "unknown"
  end

  def validate_dm_company!(target_stream_user_id)
    return if can_see_all?

    target_op_id = target_stream_user_id.to_s.delete_prefix("op_").to_i
    target_user  = User.find_by(id: target_op_id)
    return unless target_user

    target_slug = slug_for_user(target_user)
    return if Mngt::Companies.can_see_all_by_slug?(target_slug)

    unless same_company?(target_user)
      raise Error, "Mensagens diretas são permitidas apenas com a própria empresa ou com membros do Grupo MNGT"
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

    response = stream_http.request(request)
    parsed   = JSON.parse(response.body)

    unless response.is_a?(Net::HTTPSuccess)
      msg = parsed.is_a?(Hash) ? (parsed["message"] || parsed["detail"] || "HTTP #{response.code}") : "HTTP #{response.code}"
      raise Error, "Stream API error #{response.code}: #{msg}"
    end

    parsed
  rescue JSON::ParserError, Net::OpenTimeout, Net::ReadTimeout,
         Errno::ECONNREFUSED, SocketError => e
    @stream_http = nil  # force reconnect on next call
    raise Error, "Stream API unreachable: #{e.message}"
  end

  # Persistent TCP+TLS connection reused across all API calls on this instance.
  # Eliminates one TLS handshake per request (significant during full user sync).
  def stream_http
    @stream_http ||= Net::HTTP.new("chat.stream-io-api.com", 443).tap do |h|
      h.use_ssl      = true
      h.open_timeout = 5
      h.read_timeout = 10
      h.start
    end
  end
end
