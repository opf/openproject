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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module AI
  module TextTransforms
    # Brings the model output that Replace inserts in line with the pane's untrusted preview, so the
    # editor never receives macros, images or group mentions (which notify every member on save).
    class ApplicableText
      MACRO = %r{<macro\b[^>]*?(?:/>|>.*?</macro>)}m
      GROUP_MENTION = %r{<mention\b(?=[^>]*\bdata-type="group")[^>]*>(.*?)</mention>}m
      MARKDOWN_IMAGE = /!\[([^\]]*)\]\(\s*<?([^)\s>]+)>?(?:\s+"[^"]*")?\s*\)/
      HTML_IMAGE = /<img\b[^>]*>/m

      def self.call(text)
        text
          .gsub(MACRO, "")
          .gsub(GROUP_MENTION) { Regexp.last_match(1) }
          .gsub(MARKDOWN_IMAGE) { image_link(Regexp.last_match(1), Regexp.last_match(2)) }
          .gsub(HTML_IMAGE) { |tag| html_image_link(tag) }
      end

      def self.html_image_link(tag)
        image = Nokogiri::HTML5.fragment(tag).at("img")
        image_link(image&.[]("alt"), image&.[]("src"))
      end

      def self.image_link(alt, source)
        source = source.presence
        text = I18n.t("text_formatting.image_link", name: alt.presence || source).delete("[]")
        source ? "[#{text}](#{source})" : text
      end

      private_class_method :html_image_link, :image_link
    end
  end
end
