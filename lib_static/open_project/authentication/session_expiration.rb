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
  module Authentication
    module SessionExpiration
      def session_ttl_enabled?
        Setting.session_ttl_enabled? && Setting.session_ttl.to_i >= 5
      end

      def session_ttl_minutes
        Setting.session_ttl.to_i.minutes
      end

      def session_ttl_expired?
        # Only when the TTL setting exists
        return false unless session_ttl_enabled?

        # If the session is rack-provided and empty, also skip it
        return false if session.empty?

        session[:updated_at].nil? || (session[:updated_at] + session_ttl_minutes) < Time.now
      end
    end
  end
end
