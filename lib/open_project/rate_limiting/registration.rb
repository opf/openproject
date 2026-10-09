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
    # Throttles unauthenticated POST /account/register.
    # Disabled when registration_rate_limit is 0.
    #
    # Default bucket is the client IP
    # Set registration_rate_limit_per_ip to false to count per instance instead
    class Registration < Base
      class << self
        def enabled?
          Setting.registration_rate_limit.to_i.positive?
        end

        def registration_request?(req)
          req.post? && RecognizedRoute.matches?(req, controller: "account", action: "register")
        end
      end

      def default_limit
        Setting.registration_rate_limit.to_i
      end

      def default_period
        1.hour.to_i
      end

      def response_body(retry_after:, **)
        "Too many registration attempts. Try again at #{retry_after.seconds.from_now}.\n"
      end

      def per_ip?
        Setting.registration_rate_limit_per_ip
      end

      protected

      def discriminator(req)
        return unless self.class.registration_request?(req)

        per_ip? ? client_ip(req) : Setting.host_name
      end

      def client_ip(req)
        req.env["HTTP_X_REAL_IP"].presence || req.ip
      end
    end
  end
end
