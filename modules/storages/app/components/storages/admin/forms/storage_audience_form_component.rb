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
#
module Storages::Admin::Forms
  class StorageAudienceFormComponent < StorageFormComponent
    def self.wrapper_key = :storage_audience_section

    options submit_button_disabled: false

    def form_url
      query = { origin_component: "storage_audience" }
      query[:continue_wizard] = storage.id if in_wizard

      admin_settings_storage_path(storage, query)
    end

    def submit_button_options
      { disabled: submit_button_disabled }
    end

    def cancel_button_options
      { href: cancel_button_path, data: { turbo_stream: true } }
    end

    private

    def cancel_button_path
      edit_admin_settings_storage_path(storage)
    end
  end
end
