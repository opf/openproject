#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2021 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

module OpenProject::TextFormatting
  module Matchers
    # OpenProject macros for inserting setting values
    # Examples:
    #   opSetting:host_name # Outputs the Setting.host_name
    class SettingMacros < RegexMatcher
      ALLOWED_SETTINGS = %w[
        host_name
        base_url
      ].freeze

      def self.regexp
        %r{
          opSetting:(#{ALLOWED_SETTINGS.join("|")})
        }x
      end

      ##
      # Faster inclusion check before the regex is being applied
      def self.applicable?(content)
        content.include?('opSetting:')
      end

      def self.process_match(match, matched_string, _context)
        variable = match[1]
        return matched_string unless ALLOWED_SETTINGS.include?(variable)

        send variable
      end

      def self.host_name
        OpenProject::StaticRouting::UrlHelpers.host
      end

      def self.base_url
        OpenProject::Application.root_url
      end
    end
  end
end
