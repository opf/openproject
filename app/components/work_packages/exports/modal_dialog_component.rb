# frozen_string_literal: true

# -- copyright
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
# ++

module WorkPackages
  module Exports
    class ModalDialogComponent < ApplicationComponent
      MODAL_ID = "op-work-packages-export-dialog"
      EXPORT_FORM_ID = "op-work-packages-export-dialog-form"
      include OpTurbo::Streamable
      include OpPrimer::ComponentHelpers

      attr_reader :query, :project, :query_params

      def initialize(query:, project:, title:)
        super

        @query = query
        @project = project
        @query_params = ::API::V3::Queries::QueryParamsRepresenter.new(query).to_url_query(merge_params: { columns: [], title: })
      end

      def export_format_url(format)
        @project.nil? ? index_work_packages_path(format:) : project_work_packages_path(project, format:)
      end

      def export_formats_settings
        [
          { id: "pdf", icon: :"op-pdf",
            label: I18n.t("export.dialog.format.options.pdf.label"),
            component: WorkPackages::Exports::PDF::ExportSettingsComponent,
            selected: true },
          { id: "xls", icon: :"op-xls",
            label: I18n.t("export.dialog.format.options.xls.label"),
            component: WorkPackages::Exports::XLS::ExportSettingsComponent },
          { id: "csv", icon: :"op-file-csv",
            label: I18n.t("export.dialog.format.options.csv.label"),
            component: WorkPackages::Exports::CSV::ExportSettingsComponent }
        ]
      end
    end
  end
end
