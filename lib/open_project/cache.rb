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

require_relative "cache/cache_key"

module OpenProject
  ##
  # A cache accessor that ensures cache keys expire after OpenProject version bumps.
  # Using OpenProject::Cache should be preferred over using Rails.cache directly.
  module Cache
    class << self
      def fetch(*, **, &)
        Rails.cache.fetch(CacheKey.key(*), **, &)
      end

      # Like .fetch, but caches the result in RequestStore for the
      # lifetime of the current request.
      # Useful when accessing many times during a request to avoid
      # multiple cache round-trips.
      def fetch_request_cached(*, **, &)
        key = CacheKey.key(*)

        RequestStore.fetch(key) do
          Rails.cache.fetch(key, **, &)
        end
      end

      def read(name, **)
        Rails.cache.read(CacheKey.key(name), **)
      end

      def write(name, value, **)
        Rails.cache.write(CacheKey.key(name), value, **)
      end

      def delete(*)
        Rails.cache.delete(CacheKey.key(*))
      end

      def clear
        Rails.cache.clear
      end
    end
  end
end
