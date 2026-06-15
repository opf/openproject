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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module OpenProject::TextFormatting
  module Filters
    ##
    # A filter that replaces links with a rich representation. It's supposed to only replace bare links that would expose the
    # full URL in the formatted text. Deliberately named links will not be replaced.
    class LinkReplacementFilter < HTML::Pipeline::Filter
      class << self
        # Register a handler class to deal with URL replacements. A new handler will be instantiated per document. Instances are
        # expected to implement `match?` method, accepting a URI and deciding whether it will be replaced and
        # a `html_for` method, accepting a URI and returning the HTML it should be replaced with.
        # If `html_for` returns `nil` after a match occured, no replacement will happen,
        # but no other handler will be tried as well.
        def register_handler(handler)
          handlers << handler
        end

        def handlers
          @handlers ||= []
        end
      end

      def call
        links.each do |node|
          next unless plain_link?(node)

          url = parse_url(node["href"])
          next unless url

          handler = handlers.find { |h| h.match?(url) }
          next unless handler

          replacement = handler.html_for(url)
          node.replace(replacement) if replacement
        end

        doc
      end

      private

      def links
        doc.css("a")
      end

      def parse_url(string)
        URI.parse(string)
      rescue URI::InvalidURIError
        nil
      end

      def handlers
        @handlers ||= self.class.handlers.map(&:new)
      end

      def plain_link?(node)
        node.text == node["href"]
      end
    end
  end
end
