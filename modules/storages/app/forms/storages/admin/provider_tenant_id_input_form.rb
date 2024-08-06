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

module Storages::Admin
  class ProviderTenantIdInputForm < ApplicationForm
    form do |storage_form|
      storage_form.text_field(
        name: :tenant_id,
        label: I18n.t("activerecord.attributes.storages/storage.tenant"),
        visually_hide_label: false,
        required: true,
        caption: caption.html_safe, # rubocop:disable Rails/OutputSafety
        placeholder: I18n.t("storages.instructions.one_drive.tenant_id_placeholder"),
        input_width: :large
      )
    end

    private

    def caption
      href = ::OpenProject::Static::Links[:storage_docs][:one_drive_oauth_application][:href]
      I18n.t("storages.instructions.one_drive.tenant_id",
             application_link_text: render(Primer::Beta::Link.new(href:, target: "_blank")) do
               I18n.t("storages.instructions.one_drive.application_link_text")
             end)
    end
  end
end
