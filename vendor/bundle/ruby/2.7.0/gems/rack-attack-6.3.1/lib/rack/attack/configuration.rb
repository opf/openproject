# frozen_string_literal: true

require "ipaddr"

module Rack
  class Attack
    class Configuration
      DEFAULT_BLOCKLISTED_RESPONSE = lambda { |_env| [403, { 'Content-Type' => 'text/plain' }, ["Forbidden\n"]] }

      DEFAULT_THROTTLED_RESPONSE = lambda do |env|
        if Rack::Attack.configuration.throttled_response_retry_after_header
          match_data = env['rack.attack.match_data']
          now = match_data[:epoch_time]
          retry_after = match_data[:period] - (now % match_data[:period])

          [429, { 'Content-Type' => 'text/plain', 'Retry-After' => retry_after.to_s }, ["Retry later\n"]]
        else
          [429, { 'Content-Type' => 'text/plain' }, ["Retry later\n"]]
        end
      end

      attr_reader :safelists, :blocklists, :throttles, :anonymous_blocklists, :anonymous_safelists
      attr_accessor :blocklisted_response, :throttled_response, :throttled_response_retry_after_header

      def initialize
        set_defaults
      end

      def safelist(name = nil, &block)
        safelist = Safelist.new(name, &block)

        if name
          @safelists[name] = safelist
        else
          @anonymous_safelists << safelist
        end
      end

      def blocklist(name = nil, &block)
        blocklist = Blocklist.new(name, &block)

        if name
          @blocklists[name] = blocklist
        else
          @anonymous_blocklists << blocklist
        end
      end

      def blocklist_ip(ip_address)
        @anonymous_blocklists << Blocklist.new { |request| IPAddr.new(ip_address).include?(IPAddr.new(request.ip)) }
      end

      def safelist_ip(ip_address)
        @anonymous_safelists << Safelist.new { |request| IPAddr.new(ip_address).include?(IPAddr.new(request.ip)) }
      end

      def throttle(name, options, &block)
        @throttles[name] = Throttle.new(name, options, &block)
      end

      def track(name, options = {}, &block)
        @tracks[name] = Track.new(name, options, &block)
      end

      def safelisted?(request)
        @anonymous_safelists.any? { |safelist| safelist.matched_by?(request) } ||
          @safelists.any? { |_name, safelist| safelist.matched_by?(request) }
      end

      def blocklisted?(request)
        @anonymous_blocklists.any? { |blocklist| blocklist.matched_by?(request) } ||
          @blocklists.any? { |_name, blocklist| blocklist.matched_by?(request) }
      end

      def throttled?(request)
        @throttles.any? do |_name, throttle|
          throttle.matched_by?(request)
        end
      end

      def tracked?(request)
        @tracks.each_value do |track|
          track.matched_by?(request)
        end
      end

      def clear_configuration
        set_defaults
      end

      private

      def set_defaults
        @safelists = {}
        @blocklists = {}
        @throttles = {}
        @tracks = {}
        @anonymous_blocklists = []
        @anonymous_safelists = []
        @throttled_response_retry_after_header = false

        @blocklisted_response = DEFAULT_BLOCKLISTED_RESPONSE
        @throttled_response = DEFAULT_THROTTLED_RESPONSE
      end
    end
  end
end
