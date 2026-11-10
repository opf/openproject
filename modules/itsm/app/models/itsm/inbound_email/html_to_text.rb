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

module ITSM
  class InboundEmail
    class HtmlToText
      LINK_TARGET = /\A(https?|mailto):/i

      def self.call(html) = new(html).call

      def initialize(html)
        @document = Loofah.html5_document(html).scrub!(:prune)
      end

      def call
        document.css("a[href]").each { |link| link.replace(document.create_text_node(link_text(link))) }
        document.to_text(encode_special_chars: false).strip
      end

      private

      attr_reader :document

      def link_text(link)
        text = link.text.strip
        return text unless link["href"].match?(LINK_TARGET)

        target = link["href"].delete_prefix("mailto:")
        text.empty? || text == target ? target : "#{text} (#{target})"
      end
    end
  end
end
