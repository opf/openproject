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

module Wikis::Admin
  class RowComponent < OpPrimer::BorderBoxRowComponent
    alias_method :wiki_provider, :model

    def row_css_id
      ActionView::RecordIdentifier.dom_id(wiki_provider)
    end

    def name
      safe_join([name_link, provider_url_line])
    end

    def provider_type
      render(Primer::Beta::Text.new(color: :subtle)) { I18n.t("wikis.provider_types.#{wiki_provider}.name") }
    end

    def created_at
      render(Primer::Beta::Text.new(color: :subtle)) do
        I18n.t("activity.item.created_on", datetime: helpers.format_time(wiki_provider.created_at)).capitalize
      end
    end

    private

    def name_link
      render(
        Primer::Beta::Link.new(
          href: url_helpers.edit_admin_settings_wiki_provider_path(wiki_provider),
          font_weight: :bold
        )
      ) { wiki_provider.name }
    end

    def provider_url
      wiki_provider.respond_to?(:url) && wiki_provider.url
    end

    def provider_url_line
      return unless provider_url

      render(Primer::Beta::Text.new(color: :muted, font_size: :small, display: :block)) { provider_url }
    end
  end
end
