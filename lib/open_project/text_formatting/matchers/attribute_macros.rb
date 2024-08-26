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

module OpenProject::TextFormatting
  module Matchers
    # OpenProject attribute macros syntax
    # Examples:
    #   workPackageLabel:1234:subject # Outputs work package label attribute "Subject" + help text
    #   workPackageValue:1234:subject # Outputs the actual subject of #1234
    #
    #   projectLabel:statusExplanation # Outputs current project label attribute "Status description" + help text
    #   projectValue:statusExplanation # Outputs current project value for "Status description"
    class AttributeMacros < RegexMatcher
      def self.regexp
        %r{
          (\w+)(Label|Value) # The model type we try to reference
          (?::(?:([^"\s]+)|"([^"]+)"))? # Optional: An ID or subject reference
          (?::([^"\s.]+|"([^".]+)")) # The attribute name we're trying to reference
        }x
      end

      ##
      # Faster inclusion check before the regex is being applied
      def self.applicable?(content)
        content.include?("Label:") || content.include?("Value:")
      end

      def self.process_match(m, _matched_string, _context)
        # Leading string before match
        macro_attributes = {
          model: m[1],
          id: m[4] || m[3],
          attribute: m[6] || m[5]
        }
        type = m[2].downcase

        ApplicationController.helpers.content_tag "opce-macro-attribute-#{type}",
                                                  "",
                                                  data: macro_attributes
      end
    end
  end
end
