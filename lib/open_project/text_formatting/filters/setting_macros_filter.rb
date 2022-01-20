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
# See COPYRIGHT and LICENSE files for more details.
#++

module OpenProject::TextFormatting
  module Filters
    class SettingMacrosFilter < HTML::Pipeline::Filter
      ALLOWED_SETTINGS = %w[
        host_name
        base_url
      ].freeze

      def self.regexp
        %r{
        \{\{opSetting:(.+?)\}\}
        }x
      end

      def call
        return html unless applicable?

        html.gsub(self.class.regexp) do |matched_string|
          variable = $1.to_s
          variable.gsub!('\\', '')

          if ALLOWED_SETTINGS.include?(variable)
            send variable
          else
            matched_string
          end
        end
      end

      private

      def host_name
        OpenProject::StaticRouting::UrlHelpers.host
      end

      def base_url
        url_helpers.root_url.chomp('/')
      end

      def url_helpers
        @url_helpers ||= OpenProject::StaticRouting::StaticRouter.new.url_helpers
      end

      ##
      # Faster inclusion check before the regex is being applied
      def applicable?
        html.include?('{{opSetting:')
      end
    end
  end
end
