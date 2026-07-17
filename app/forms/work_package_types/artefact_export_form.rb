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

module WorkPackageTypes
  class ArtefactExportForm < ApplicationForm
    form do |f|
      f.radio_button_group(
        name: :artefact_export_mode,
        label: I18n.t("types.edit.export_configuration.artefact_export.label")
      ) do |group|
        group.radio_button(
          value: Type::ArtefactExport::OFF,
          checked: checked?(Type::ArtefactExport::OFF),
          disabled: readonly?,
          label: I18n.t("types.edit.export_configuration.artefact_export.off_mode.label"),
          caption: I18n.t("types.edit.export_configuration.artefact_export.off_mode.caption")
        )
        group.radio_button(
          value: Type::ArtefactExport::ATTACHMENT,
          checked: checked?(Type::ArtefactExport::ATTACHMENT),
          disabled: readonly?,
          label: I18n.t("types.edit.export_configuration.artefact_export.attachment.label"),
          caption: I18n.t("types.edit.export_configuration.artefact_export.attachment.caption")
        )
        group.radio_button(
          value: Type::ArtefactExport::FILE_LINK,
          checked: checked?(Type::ArtefactExport::FILE_LINK),
          label: file_link_label,
          caption: I18n.t("types.edit.export_configuration.artefact_export.file_link.caption"),
          disabled: readonly? || !file_link_available?
        )
      end
    end

    private

    def readonly? = @builder.options[:readonly] == true

    def checked?(value)
      value == (model.artefact_export_mode.presence || Type::ArtefactExport::DEFAULT)
    end

    def file_link_label
      label = I18n.t("types.edit.export_configuration.artefact_export.file_link.label")
      return label if file_link_available?

      "#{label} (#{I18n.t('types.edit.export_configuration.artefact_export.unavailable')})"
    end

    def file_link_available?
      return @file_link_available if defined?(@file_link_available)

      @file_link_available = Storages::NextcloudStorage.automatic_management_enabled.exists?
    end
  end
end
