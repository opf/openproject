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

module API
  module Utilities
    class ResourceLinkParser
      # N.B. valid characters for URL path segments as of
      # http://tools.ietf.org/html/rfc3986#section-3.3
      SEGMENT_CHARACTER = '(\w|[-~!$&\'\(\)*+\.,:;=@]|%[0-9A-Fa-f]{2})'.freeze
      RESOURCE_REGEX =
        "/api/v(?<version>\\d)/(?<namespace>[\\w/]+)/(?<id>#{SEGMENT_CHARACTER}+)\\z".freeze

      class << self
        def parse(resource_link)
          parse_resource(resource_link)
        end

        def parse_id(resource_link,
                     property:,
                     expected_version: nil,
                     expected_namespace: nil)
          raise ArgumentError unless resource_link

          resource = parse(resource_link)

          if resource
            version_valid = matches_expectation?(expected_version, resource[:version])
            namespace_valid = matches_expectation?(expected_namespace, resource[:namespace])
          end

          unless resource && version_valid && namespace_valid
            expected_link = make_expected_link(expected_version, expected_namespace)
            fail ::API::Errors::InvalidResourceLink.new(property, expected_link, resource_link)
          end

          resource[:id]
        end

        private

        def parse_resource(resource_link)
          match = resource_matcher.match(resource_link)

          return nil unless match

          {
            version: match[:version],
            namespace: match[:namespace],
            id: unescape(match[:id])
          }
        end

        def resource_matcher
          @resource_matcher ||= Regexp.compile(RESOURCE_REGEX)
        end

        def unescape(string)
          @unescaper ||= Addressable::Template.new("{+id}")

          @unescaper.extract(string)["id"]
        end

        # returns whether expectation and actual are identical
        # will always be true if there is no expectation (nil)
        def matches_expectation?(expected, actual)
          expected.nil? || Array(expected).any? { |e| e.to_s == actual }
        end

        def make_expected_link(version, namespaces)
          version = "v#{version}" || ":apiVersion"
          namespaces = Array(namespaces || ":resource")

          namespaces.map { |namespace| "/api/#{version}/#{namespace}/:id" }
        end
      end
    end
  end
end
