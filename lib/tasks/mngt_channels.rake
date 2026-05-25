# frozen_string_literal: true

namespace :mngt do
  # ---------------------------------------------------------------------------
  # Provision the 5 company "Geral" channels in Stream Chat.
  #
  # Creates `{slug}--geral` for every company in Mngt::Companies::COMPANIES,
  # sets the friendly name "Geral", then adds all eligible members:
  #   - CSC (Grupo MNGT) users go into ALL channels.
  #   - Other company users go only into their own channel.
  #
  # Safe to re-run — Stream API is idempotent for channel creation.
  # ---------------------------------------------------------------------------
  desc "Create and populate company Geral channels in Stream Chat (idempotent)"
  task provision_channels: :environment do
    unless Mngt::Stream.configured?
      puts "ERROR: Stream is not configured (check STREAM_API_KEY / STREAM_API_SECRET)."
      exit 1
    end

    admin_user = User.active.where(admin: true).first
    unless admin_user
      puts "ERROR: No active admin user found."
      exit 1
    end

    svc = Mngt::StreamChannelService.new(admin_user)

    Mngt::Companies::COMPANIES.each_key do |slug|
      channel_id = "#{slug}--geral"
      print "  Provisioning #{channel_id} … "
      svc.provision_team_channel(channel_id, channel_name: "Geral")
      puts "done"
    end

    puts "\nAll channels provisioned."
  end

  # ---------------------------------------------------------------------------
  # Show which Stream team channels currently exist and their member counts.
  # ---------------------------------------------------------------------------
  desc "List existing Stream team channels"
  task list_channels: :environment do
    unless Mngt::Stream.configured?
      puts "ERROR: Stream is not configured."
      exit 1
    end

    admin_user = User.active.where(admin: true).first
    unless admin_user
      puts "ERROR: No active admin user found."
      exit 1
    end

    require "net/http"
    require "json"
    require "openssl"
    require "base64"

    api_key    = Mngt::Stream.api_key
    api_secret = Mngt::Stream.api_secret

    header  = Base64.urlsafe_encode64('{"alg":"HS256","typ":"JWT"}', padding: false)
    payload = Base64.urlsafe_encode64({ server: true }.to_json, padding: false)
    input   = "#{header}.#{payload}"
    sig     = Base64.urlsafe_encode64(OpenSSL::HMAC.digest("SHA256", api_secret, input), padding: false)
    token   = "#{input}.#{sig}"

    uri = URI("https://chat.stream-io-api.com/channels?api_key=#{api_key}")
    req = Net::HTTP::Post.new(uri)
    req["Authorization"]    = token
    req["stream-auth-type"] = "jwt"
    req["Content-Type"]     = "application/json"
    req.body = { filter_conditions: { type: "team" }, sort: [{ field: "id", direction: 1 }],
                 message_limit: 0, limit: 100 }.to_json

    http = Net::HTTP.new("chat.stream-io-api.com", 443)
    http.use_ssl = true
    resp   = http.request(req)
    parsed = JSON.parse(resp.body)

    channels = parsed["channels"] || []
    if channels.empty?
      puts "No team channels found."
    else
      puts "%-40s %s" % ["Channel ID", "Name"]
      puts "-" * 60
      channels.each do |ch|
        meta = ch["channel"]
        puts "%-40s %s" % [meta["id"], meta["name"].to_s]
      end
      puts "\nTotal: #{channels.size}"
    end
  end

  # ---------------------------------------------------------------------------
  # Show Stream members for each team channel + user's channel membership.
  # Usage:  rake mngt:channel_members
  #         rake mngt:channel_members USER_ID=42
  # ---------------------------------------------------------------------------
  desc "Show Stream membership for team channels (optionally filtered by USER_ID)"
  task channel_members: :environment do
    unless Mngt::Stream.configured?
      puts "ERROR: Stream is not configured."
      exit 1
    end

    target_op_id = ENV["USER_ID"] ? "op_#{ENV['USER_ID']}" : nil

    admin_user = User.active.where(admin: true).first
    svc = Mngt::StreamChannelService.new(admin_user)

    Mngt::Companies::COMPANIES.each_key do |slug|
      ch_id = "#{slug}--geral"
      print "#{ch_id}: "

      begin
        resp = svc.__send__(:stream_post, "/channels/team/#{ch_id}/query", {
          state: true, watch: false, presence: false
        })
        members = (resp["members"] || []).map { |m| m.dig("user", "id") }
        puts "#{members.size} members"
        if target_op_id
          in_ch = members.include?(target_op_id)
          puts "  -> #{target_op_id} is #{in_ch ? '✓ MEMBER' : '✗ NOT a member'}"
        end
      rescue Mngt::StreamChannelService::Error => e
        puts "ERROR: #{e.message}"
      end
    end

    if target_op_id.nil?
      puts "\nTip: run with USER_ID=<id> to check a specific user"
    end
  end

  # ---------------------------------------------------------------------------
  # Clear per-user Stream channel cache (forces re-add on next chat open).
  # ---------------------------------------------------------------------------
  desc "Clear Stream channel membership cache for all users"
  task clear_channel_cache: :environment do
    count = 0
    User.active.find_each do |u|
      key = "mngt_stream_user_team_channels_op_#{u.id}"
      Rails.cache.delete(key)
      count += 1
    end
    # Also clear the all-users upsert cache so users get re-synced to Stream
    Rails.cache.delete("mngt_stream_all_users_upserted_v5")
    puts "Cleared cache for #{count} users."
  end
end
