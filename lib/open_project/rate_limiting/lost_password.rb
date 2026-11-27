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
    class LostPassword < Base
      class << self
        def response_body(retry_after:, **)
          "Too many requests to reset your password. Try again at #{retry_after.seconds.from_now}.\n"
        end
      end

      def default_limit
        3
      end

      def default_period
        1.hour.to_i
      end

      protected

      def default_enabled?
        false
      end

      def discriminator(req)
        if req.post? && req.path.end_with?("/account/lost_password")
          req.env.dig "rack.request.form_hash", "mail"
        end
      end
    end
  end
end
