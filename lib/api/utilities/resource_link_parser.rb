#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

module API
  module Utilities
    module ResourceLinkParser
      # N.B. valid characters for URL path segments as of
      # http://tools.ietf.org/html/rfc3986#section-3.3
      SEGMENT_CHARACTER = '(\w|[-~!$&\'\(\)*+\.,:;=@]|%[0-9A-Fa-f]{2})'
      RESOURCE_REGEX = "/api/v(?<version>\\d)/(?<namespace>\\w+)/(?<id>#{SEGMENT_CHARACTER}+)\\z"
      SO_REGEX = "/api/v(?<version>\\d)/string_objects/?\\?value=(?<id>#{SEGMENT_CHARACTER}*)\\z"

      class << self
        def parse(resource_link)
          # string objects have a quite different format from the usual resources (query-parameter)
          # we therefore have a specific regex to deal with them and a generic one for all others
          parse_string_object(resource_link) || parse_resource(resource_link)
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
            id: ::URI.unescape(match[:id])
          }
        end

        def parse_string_object(resource_link)
          match = string_object_matcher.match(resource_link)

          return nil unless match

          {
            version: match[:version],
            namespace: 'string_objects',
            id: ::URI.unescape(match[:id])
          }
        end

        def resource_matcher
          @resource_matcher ||= Regexp.compile(RESOURCE_REGEX)
        end

        def string_object_matcher
          @string_object_matcher ||= Regexp.compile(SO_REGEX)
        end

        # returns whether expectation and actual are identical
        # will always be true if there is no expectation (nil)
        def matches_expectation?(expected, actual)
          expected.nil? || expected.to_s == actual
        end

        def make_expected_link(version, namespace)
          version = "v#{version}" || ':apiVersion'
          namespace = namespace || ':resource'
          "/api/#{version}/#{namespace}/:id"
        end
      end
    end
  end
end
