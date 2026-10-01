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
module OpenProject::TextFormatting
  module Filters
    class ExternalLinkCaptureFilter < HTML::Pipeline::Filter
      include OpenProject::StaticRouting::UrlHelpers

      def call
        return doc unless applicable?

        doc.css("a[href]").each do |node|
          url = node["href"]
          next if internal_link?(url)

          node["href"] = external_redirect(url:)
          node["target"] = "_blank"
        end

        doc
      end

      def applicable?
        Setting.capture_external_links? && EnterpriseToken.allows_to?(:capture_external_links)
      end

      private

      def external_redirect(url:)
        url_helpers.external_redirect_url(url:)
      end

      def internal_link?(href)
        return true if href.blank?
        return true if href.start_with?("#", "/")

        # Only capture HTTP/HTTPS links, allow all other schemes (mailto, tel, ical, custom protocols, etc.)
        return true unless href.start_with?("http", "https")

        # Check if it's an internal link
        internal_url = "#{Setting.protocol}://#{Setting.host_name}"
        return true if href.start_with?(internal_url)

        # Additional host names check
        Setting.additional_host_names.each do |additional_host|
          additional_url = "#{Setting.protocol}://#{additional_host}"
          return true if href.start_with?(additional_url)
        end

        false
      end

      def url_helpers
        @url_helpers ||= OpenProject::StaticRouting::StaticUrlHelpers.new
      end
    end
  end
end
