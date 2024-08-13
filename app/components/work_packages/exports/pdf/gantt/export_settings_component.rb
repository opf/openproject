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
    module PDF
      module Gantt
        class ExportSettingsComponent < BaseExportSettingsComponent
          def gantt_selects
            [
              {
                name: "gantt_mode",
                label: I18n.t("export.dialog.pdf.gantt_zoom_levels.label"),
                caption: I18n.t("export.dialog.pdf.gantt_zoom_levels.caption"),
                options: gantt_zoom_levels
              },
              {
                name: "gantt_width",
                label: I18n.t("export.dialog.pdf.column_width.label"),
                options: gantt_column_widths
              },
              {
                name: "paper_size",
                label: I18n.t("export.dialog.pdf.paper_size.label"),
                caption: I18n.t("export.dialog.pdf.paper_size.caption"),
                options: pdf_paper_sizes
              }
            ]
          end

          def gantt_zoom_levels
            [
              { label: t("export.dialog.pdf.gantt_zoom_levels.options.days"), value: "day", default: true },
              { label: t("export.dialog.pdf.gantt_zoom_levels.options.weeks"), value: "week" },
              { label: t("export.dialog.pdf.gantt_zoom_levels.options.months"), value: "month" },
              { label: t("export.dialog.pdf.gantt_zoom_levels.options.quarters"), value: "quarter" }
            ]
          end

          def gantt_column_widths
            [
              { label: t("export.dialog.pdf.column_width.options.narrow"), value: "narrow" },
              { label: t("export.dialog.pdf.column_width.options.medium"), value: "medium", default: true },
              { label: t("export.dialog.pdf.column_width.options.wide"), value: "wide" },
              { label: t("export.dialog.pdf.column_width.options.very_wide"), value: "very_wide" }
            ]
          end

          def pdf_paper_sizes
            [
              { label: "A4", value: "A4", default: true },
              { label: "A3", value: "A3" },
              { label: "A2", value: "A2" },
              { label: "A1", value: "A1" },
              { label: "A0", value: "A0" },
              { label: "Executive", value: "EXECUTIVE" },
              { label: "Folio", value: "FOLIO" },
              { label: "Letter", value: "LETTER" },
              { label: "Tabloid", value: "TABLOID" }
            ]
          end
        end
      end
    end
  end
end
