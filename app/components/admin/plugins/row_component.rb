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

module Admin
  module Plugins
    class RowComponent < OpPrimer::BorderBoxRowComponent
      alias_method :plugin, :model

      def name
        safe_join([name_text, description_text, url_link])
      end

      def author
        return plugin.author if plugin.author_url.blank?

        render(Primer::Beta::Link.new(href: plugin.author_url)) { plugin.author }
      end

      def version
        return I18n.t(:label_bundled) if plugin.bundled

        plugin.version
      end

      private

      def name_text
        render(Primer::Beta::Text.new(font_weight: :bold)) { plugin.name }
      end

      def description_text
        return if plugin.description.blank?

        render(Primer::Beta::Text.new(display: :block, color: :subtle)) { plugin.description }
      end

      def url_link
        return if plugin.url.blank?

        render(Primer::Beta::Link.new(href: plugin.url, display: :block)) { plugin.url }
      end
    end
  end
end
