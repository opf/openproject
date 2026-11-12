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

module Storages::Admin
  class AccessManagementForm < ApplicationForm
    form do |access_management_form|
      access_management_form.radio_button_group(name: :automatic_management_enabled, validation_message:) do |radio_buttons|
        radio_buttons.radio_button(
          value: true,
          checked: @storage.automatic_management_enabled?,
          label: access_management_translation("automatic_management"),
          caption: access_management_translation("automatic_management_description"),
          visually_hide_label: false
        )

        radio_buttons.radio_button(
          value: false,
          checked: !@storage.automatic_management_enabled?,
          label: access_management_translation("manual_management"),
          caption: access_management_translation("manual_management_description"),
          visually_hide_label: false
        )
      end
    end

    def initialize(storage:)
      super()
      @storage = storage
    end

    private

    def validation_message
      @storage.errors.full_messages.join(", ") if @storage.errors.any?
    end

    def access_management_translation(key)
      if @storage.provider_type_one_drive?
        I18n.t("storages.file_storage_view.one_drive.access_management.#{key}")
      else
        I18n.t("storages.file_storage_view.access_management.#{key}")
      end
    end
  end
end
