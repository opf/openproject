# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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
  class StorageButtonComponent < ApplicationComponent
    options action: :new,
            size: :medium,
            tag: :a

    alias_method :storage, :model

    def button_options
      { size:,
        tag:,
        role: :button }.merge(button_options_from_action)
    end

    private

    def button_options_from_action
      case action
      when :new
        { scheme: :primary, href: Rails.application.routes.url_helpers.new_admin_settings_storage_path,
          aria: { label: I18n.t("storages.label_add_new_storage") } }
      when :delete
        { scheme: :danger, href: Rails.application.routes.url_helpers.admin_settings_storage_path(storage),
          aria: { label: I18n.t("storages.label_delete_storage") },
          data: { confirm: I18n.t('storages.delete_warning.storage') },
          method: :delete }
      end
    end

    def label
      { new: I18n.t("storages.label_storage"),
        delete: I18n.t('button_delete') }[action]
    end

    def icon_name
      { new: 'plus',
        delete: 'trash' }[action]
    end
  end
end
