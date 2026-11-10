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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module OpenProject
  module OpenTelemetry
    # The excon instrumentation copies datum[:query] into the 'url.query' span attribute as is.
    # Excon also accepts a Hash there (fog-aws always passes one), which the SDK rejects with
    # "invalid span attribute value type Hash for key 'url.query'".
    # Serializing it the same way Excon would keeps the request on the wire unchanged.
    module ExconHashQuery
      def self.apply!
        %w[Stable Dup].each do |variant|
          middleware = "OpenTelemetry::Instrumentation::Excon::Middlewares::#{variant}::TracerMiddleware".safe_constantize
          middleware&.prepend(self)
        end
      end

      def request_call(datum)
        if datum[:query].is_a?(Hash)
          datum[:query] = ::Excon::Utils.query_string(datum).delete_prefix("?").presence
        end

        super
      end
    end
  end
end
