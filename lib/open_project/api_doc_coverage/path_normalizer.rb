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
  module ApiDocCoverage
    # Converts a Grape route path template into the canonical OpenAPI path used
    # in docs/api/apiv3 (which keeps the /api/v3 prefix), and extracts the owning
    # module (first path segment after the prefix).
    class PathNormalizer
      FORMAT_SUFFIX = /\(\/?\.:format\)/
      VERSION_PREFIX = %r{\A/:version}
      # Matches both regular Grape params (:id) and splat params (*id, used where
      # a segment may contain slashes, e.g. actions/:id). Both map to {id} to
      # match the OpenAPI path style.
      NAMED_PARAM = /[:*](\w+)/
      API_PREFIX = "/api/v3"

      def self.canonical_path(grape_path)
        path = grape_path
          .sub(FORMAT_SUFFIX, "")
          .sub(VERSION_PREFIX, API_PREFIX)
          .gsub(NAMED_PARAM, '{\1}')
          .chomp("/")
        path.empty? ? API_PREFIX : path
      end

      def self.module_name(canonical_path)
        segment = canonical_path.delete_prefix(API_PREFIX).split("/").reject(&:empty?).first
        segment || "(root)"
      end
    end
  end
end
