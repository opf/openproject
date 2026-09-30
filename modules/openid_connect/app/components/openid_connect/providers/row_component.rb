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

module OpenIDConnect
  module Providers
    class RowComponent < ::OpPrimer::BorderBoxRowComponent
      def provider
        model
      end

      def name
        concat(provider_name)

        unless provider.configured?
          incomplete_label
        end
      end

      def provider_name
        render(
          Primer::Beta::Link.new(
            href: url_for(action: :show, id: provider.id),
            font_weight: :bold,
            mr: 1
          )
        ) { provider.display_name }
      end

      def incomplete_label
        render(Primer::Beta::Label.new(scheme: :attention)) { I18n.t(:label_incomplete) }
      end

      def type
        I18n.t("openid_connect.providers.#{provider.oidc_provider}.name")
      end

      def row_css_class
        [
          "openid-connect--provider-row",
          "openid-connect--provider-row-#{model.id}"
        ].join(" ")
      end

      def button_links
        []
      end

      def users
        provider.user_count.to_s
      end

      def creator
        helpers.avatar(provider.creator, size: :mini, hide_name: false)
      end

      def created_at
        helpers.format_time provider.created_at
      end
    end
  end
end
