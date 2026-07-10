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
  module Helpers
    # Shared helper for building composite ARIA labels on macro-generated links.
    # Combines the visible link text with a plain-text context description,
    # stripping any HTML from both before interpolating.
    module AccessibleLinkLabel
      def accessible_link_label(name, description)
        visible_name = plain_text(name)
        plain_description = plain_text(description)
        I18n.t("accessibility.macro.aria_label_with_name",
               name: visible_name,
               description: plain_description)
      end

      private

      def plain_text(html)
        text = CGI.unescapeHTML(html.to_s)
        text.include?("<") ? Nokogiri::HTML.fragment(text).text.squish : text.squish
      end
    end
  end
end
