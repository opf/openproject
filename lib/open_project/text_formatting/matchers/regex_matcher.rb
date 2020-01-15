#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See docs/COPYRIGHT.rdoc for more details.
#++

module OpenProject::TextFormatting
  module Matchers
    class RegexMatcher
      def self.call(node, doc:, context:)
        content = node.to_html
        return unless applicable?(content)

        # Replace the content
        if process_node!(content, context)
          node.replace(content)
        end
      end

      ##
      # Quick bypass method if the content is not applicable for this matcher
      def self.applicable?(_content)
        true
      end

      ##
      # Process the node's html and possibly, replace it
      def self.process_node!(content, context)
        return nil unless content.present?

        content.gsub!(regexp) do |matched_string|
          matchdata = Regexp.last_match
          process_match matchdata, matched_string, context
        end
      end

      ##
      # Get the regexp that matches the content
      def self.regexp
        raise NotImplementedError
      end

      ##
      # Called with a match from the regexp on the node's content
      def self.process_match(matchdata, matched_string, context)
        raise NotImplementedError
      end

      ##
      # Helper method for url helpers
      def controller; end
    end
  end
end
