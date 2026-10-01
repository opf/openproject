# frozen_string_literal: true

module Herfy
  module ControlCenter
    # Scheduled directory sync (rake herfy:control_center:sync).
    # Only touches users that already log in through Control Center (identified
    # by the OIDC provider) unless HERFY_CC_CREATE_USERS=true, which also
    # pre-creates accounts for every Control Center user.
    class Sync
      def initialize(base_url: ENV["HERFY_CC_API_URL"].presence || ENV.fetch("HERFY_CC_ISSUER", "https://controlcenter.herfy.com"),
                     client_id: ENV.fetch("HERFY_CC_CLIENT_ID"),
                     client_secret: ENV.fetch("HERFY_CC_CLIENT_SECRET"),
                     create_users: ENV["HERFY_CC_CREATE_USERS"] == "true")
        @base = base_url.chomp("/")
        @client_id = client_id
        @client_secret = client_secret
        @create_users = create_users
        @stats = Hash.new(0)
      end

      def call
        fetch_users.each { |record| sync_record(record) }
        Rails.logger.info("[herfy] control center sync: #{@stats}")
        puts "Control Center sync: #{@stats.to_h}"
        @stats
      end

      def sync_record(record)
        identity = record.fetch("identity", {})
        email = identity["email"].to_s.downcase
        return if email.blank?

        user = User.find_by("LOWER(mail) = ?", email) || (create_user(identity, email) if @create_users && identity["active"])
        return @stats[:skipped] += 1 unless user

        if identity["active"] == false
          user.locked! unless user.locked? || user.admin?
          return @stats[:locked] += 1
        end
        user.activate! if user.locked? && identity["active"]
        Herfy::ControlCenter.apply_claims(user, Herfy::ControlCenter.claims_from_export(record))
        @stats[:updated] += 1
      end

      private

      def create_user(identity, email)
        first, *rest = identity["full_name"].to_s.split
        user = User.new(login: email, mail: email, firstname: first.presence || email, lastname: rest.join(" ").presence || "-",
                        status: Principal.statuses[:active], language: Setting.default_language)
        user.identity_url = "#{Herfy::ControlCenter::PROVIDER_SLUG}:#{identity['id']}" if identity["id"]
        user.save!(validate: false)
        @stats[:created] += 1
        user
      end

      def token
        res = Net::HTTP.post_form(URI("#{@base}/oauth/token"),
                                  "grant_type" => "client_credentials", "client_id" => @client_id, "client_secret" => @client_secret)
        raise "token request failed: #{res.code}" unless res.is_a?(Net::HTTPSuccess)

        JSON.parse(res.body).fetch("access_token")
      end

      def fetch_users
        bearer = token
        users = []
        cursor = nil
        loop do
          uri = URI("#{@base}/api/users/export")
          uri.query = URI.encode_www_form({ include_inactive: true, limit: 500, cursor: }.compact)
          res = Net::HTTP.get_response(uri, "Authorization" => "Bearer #{bearer}")
          raise "export failed: #{res.code}" unless res.is_a?(Net::HTTPSuccess)

          page = JSON.parse(res.body)
          users.concat(page.fetch("users"))
          cursor = page["next_cursor"]
          break if cursor.blank?
        end
        users
      end
    end
  end
end
