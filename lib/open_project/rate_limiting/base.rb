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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module OpenProject
  module RateLimiting
    class Base
      include RecognizedRoute

      class << self
        def rule_name
          name.demodulize.underscore
        end

        def enabled?
          if settings.key?(:enabled)
            ActiveRecord::Type::Boolean.new.cast(settings[:enabled])
          else
            enabled_by_default?
          end
        end

        def enabled_by_default?
          true
        end

        def settings
          value = OpenProject::Configuration.rate_limiting.with_indifferent_access.fetch(rule_name, {})
          value = { enabled: value } if [true, false].include?(value)
          value
        end
      end

      def apply!
        Rack::Attack.throttle(rule_name, limit:, period:) do |request|
          discriminator(request)
        end

        self
      end

      delegate :settings, :rule_name, to: :class

      def response(request)
        match_data = request.env["rack.attack.match_data"]
        now = match_data[:epoch_time]
        retry_after = match_data[:period] - (now % match_data[:period])

        headers = {
          "RateLimit-Limit" => match_data[:limit].to_s,
          "RateLimit-Remaining" => "0",
          "RateLimit-Reset" => (now + (match_data[:period] - (now % match_data[:period]))).to_s
        }

        body = response_body(request:, now:, retry_after:)
        [429, headers, [body]]
      end

      def response_body(retry_after:, **)
        "Your request has been throttled. Try again at #{retry_after.seconds.from_now}.\n"
      end

      def blocked_response
        [429, { "Content-Type" => "text/plain" }, [blocked_response_body]]
      end

      def blocked_response_body
        "Your request has been blocked.\n"
      end

      protected

      # Provide a limit callback proc for the request, or use the default limit
      # e.g.,
      # def limit
      #   proc { |req| req.env["REMOTE_USER"] == "admin" ? 100 : 1 }
      # end
      def limit
        settings[:limit].presence || default_limit
      end

      def period
        settings[:period].presence || default_period
      end

      def session_id(env)
        return if session_cookie_name.nil?

        String(env["HTTP_COOKIE"]).scan(/#{session_cookie_name}=([^;]+)/).flatten.first
      end

      def remote_ip(env)
        env["X-Real-IP"].presence || env["Remote-Addr"]
      end

      def http_auth(env)
        env["HTTP_AUTHORIZATION"].presence
      end

      def session_cookie_name
        @session_cookie_name ||= OpenProject::Configuration["session_cookie_name"]
      end

      def default_enabled?
        false
      end

      def discriminator(_request)
        raise SubclassResponsibilityError
      end

      def default_limit
        raise SubclassResponsibilityError
      end

      def default_period
        raise SubclassResponsibilityError
      end
    end
  end
end
