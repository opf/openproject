# frozen_string_literal:true

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

module Storages
  class UrlBuilder
    class << self
      def url(uri, *path_fragments)
        URI.join(uri.origin,
                 ensure_sub_path(uri.path),
                 *split_and_escape(path_fragments))
           .to_s
      end

      def path(*path_fragments)
        URI.join(URI("https://drop.me/"), *split_and_escape(path_fragments)).path
      end

      private

      def ensure_sub_path(fragment)
        fragment.ends_with?("/") ? fragment : "#{fragment}/"
      end

      def split_and_escape(fragments)
        return fragments if fragments.empty?

        single_fragments = fragments
                             .map { |f| f.split("/") }
                             .flatten
                             .reject(&:empty?)
                             .each { |f| ensure_unescaped_fragments(f) }
                             .map { |f| CGI.escapeURIComponent(f) }

        return [] if single_fragments.empty?

        single_fragments[..-2]
          .map { |f| "#{f}/" }
          .push(single_fragments.last)
      end

      def ensure_unescaped_fragments(fragment)
        raise ArgumentError, "URL-escaped character found: #{fragment}" if improved_unescape(fragment) != fragment
      end

      def improved_unescape(fragment)
        # If the fragment contains a '+' character, it will be replaced with its URL-encoded equivalent '%2B' before
        # decoding. This is because '+' is the only reserved character, that will get replaced by CGI.unescape
        # (with a whitespace ' ').
        CGI.unescape(fragment.gsub("+", "%2B"))
      end
    end
  end
end
