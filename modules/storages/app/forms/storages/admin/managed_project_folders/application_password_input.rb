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

module Storages::Admin::ManagedProjectFolders
  class ApplicationPasswordInput < ApplicationForm
    form do |application_password_form|
      application_password_form.text_field(
        name: :password,
        label: I18n.t(:"storages.label_managed_project_folders.application_password"),
        required: true,
        caption: application_password_caption,
        value: nil, # IMPORTANT: We don't want to show the password in the form
        placeholder: @storage.password.present? ? "••••••••••••••••" : nil,
        input_width: :large
      )
    end

    def initialize(storage:)
      super()
      @storage = storage
    end

    private

    def application_password_caption
      I18n.t(:"storages.instructions.managed_project_folders_application_password_caption",
             provider_type_link:).html_safe
    end

    def provider_type_link
      render(
        Primer::Beta::Link.new(
          href: Storages::UrlBuilder.url(@storage.uri, "settings/admin/openproject"),
          target: "_blank"
        )
      ) { I18n.t("storages.instructions.#{@storage.short_provider_type}.integration") }
    end
  end
end
