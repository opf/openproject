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

module API
  module Caching
    module Helpers
      def with_etag!(key)
        etag = %(W/"#{::Digest::SHA1.hexdigest(key.to_s)}")
        error!("Not Modified".freeze, 304) if headers["If-None-Match".freeze] == etag

        header "ETag".freeze, etag
      end

      ##
      # Store a represented object in its JSON representation
      def cache(key, args = {})
        # Save serialization since we're only dealing with strings here
        args[:raw] = true

        json = Rails.cache.fetch(key, args) do
          result = yield
          result.to_json
        end

        ::API::Caching::StoredRepresenter.new json
      end
    end
  end
end
