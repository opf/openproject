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

module Storages
  module Admin
    class EditFormHeaderComponent < ApplicationComponent # rubocop:disable OpenProject/AddPreviewForViewComponent
      TAB_NAVS = %i[
        edit
        project_storages
      ].freeze

      def initialize(storage:, selected:)
        super
        @storage = storage
        @selected = selected
      end

      def tab_selected?(tab_name)
        TAB_NAVS.include?(tab_name) &&
          tab_name == @selected
      end

      def label_storage_name_with_provider_label
        "#{h(@storage.name)} #{label_storage_provider_part}".html_safe # rubocop:disable Rails/OutputSafety
      end

      def label_storage_provider_part
        render(Primer::Beta::Text.new(tag: :span, font_weight: :light, color: :muted)) do
          "(#{I18n.t("storages.provider_types.#{h(@storage.short_provider_type)}.name")})"
        end
      end

      def breadcrumbs_items
        [{ href: admin_index_path, text: t("label_administration") },
         { href: admin_settings_storages_path, text: t("project_module_storages") },
         @storage.name]
      end
    end
  end
end
