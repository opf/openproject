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
#

module Storages::Admin
  class RowComponent < OpPrimer::BorderBoxRowComponent
    alias_method :storage, :model

    def row_css_id
      ActionView::RecordIdentifier.dom_id(storage)
    end

    def name
      safe_join(
        [
          content_tag(:div) do
            safe_join([name_link, incomplete_label, unhealthy_label])
          end,
          host_line
        ]
      )
    end

    def provider_type
      render(
        Primer::Beta::Truncate.new(font_weight: :light, data: { test_selector: "storage-provider" })
      ) { I18n.t("storages.provider_types.#{storage.short_provider_type}.name") }
    end

    def creator
      render(
        Users::AvatarComponent.new(
          user: storage.creator,
          size: :mini,
          link: false,
          show_name: true,
          name_classes: "hidden-for-tablet-and-small-laptops"
        )
      )
    end

    def created_at
      render(Primer::Beta::Text.new(font_weight: :light)) do
        I18n.t("activity.item.created_on", datetime: helpers.format_time(storage.created_at)).capitalize
      end
    end

    private

    def name_link
      render(
        Primer::Beta::Link.new(
          href: url_helpers.edit_admin_settings_storage_path(storage),
          font_weight: :bold,
          mr: 1,
          data: { test_selector: "storage-name" }
        )
      ) { storage.name }
    end

    def incomplete_label
      return if storage.configured?

      render(Primer::Beta::Label.new(scheme: :attention, test_selector: "label-incomplete")) { I18n.t(:label_incomplete) }
    end

    def unhealthy_label
      return unless storage.health_unhealthy?

      render(Primer::Beta::Label.new(scheme: :danger, test_selector: "storage-health-label-error")) do
        I18n.t("storages.health.label_error")
      end
    end

    def host_line
      render(
        Primer::Beta::Truncate.new(font_weight: :light, color: :subtle, data: { test_selector: "storage-host" })
      ) { storage.host }
    end
  end
end
