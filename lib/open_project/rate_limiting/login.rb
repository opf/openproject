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
    # Per-account HTTP-layer brute-force protection for POST /login.
    #
    # Uses Rack::Attack::Allow2Ban: the first BURST_LIMIT attempts within
    # BURST_PERIOD are allowed through; once the limit is exceeded a ban flag
    # is written that blocks all subsequent attempts for BAN_PERIOD.
    #
    # Enabled by default.  Disable or tune via configuration.yml:
    #
    #   rate_limiting:
    #     login:
    #       enabled: false
    class Login < Base
      BURST_LIMIT  = 20
      BURST_PERIOD = 1.minute.to_i
      BAN_PERIOD   = 30.minutes.to_i

      class << self
        def enabled_by_default?
          true
        end
      end

      def apply!
        Rack::Attack.blocklist(rule_name) do |req|
          next false unless req.post? && req.path == "/login"

          username = req.env.dig("rack.request.form_hash", "username").to_s.downcase.presence
          next false unless username

          Rack::Attack::Allow2Ban.filter(
            "login:#{username}",
            maxretry: burst_limit,
            findtime: burst_period,
            bantime: ban_period
          ) { true }
        end

        self
      end

      def blocked_response_body
        "Too many login attempts. Please try again later.\n"
      end

      protected

      def burst_limit
        settings[:burst_limit].presence&.to_i || BURST_LIMIT
      end

      def burst_period
        settings[:burst_period].presence&.to_i || BURST_PERIOD
      end

      def ban_period
        settings[:ban_period].presence&.to_i || BAN_PERIOD
      end
    end
  end
end
