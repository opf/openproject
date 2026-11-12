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
    class APIV3 < Base
      def self.enabled_by_default?
        false
      end

      def default_limit
        6 # requests
      end

      def default_period
        3 # seconds
      end

      protected

      def discriminator(req)
        if req.post? && req.path.start_with?("/api/v3/") && req.path.end_with?("/form")
          session_id(req.env) || http_auth(req.env)
        end
      end

      def response_body(**)
        API::V3::Errors::ErrorRepresenter.new(ThrottledApiError.new).to_json
      end
    end
  end
end
