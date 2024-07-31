# frozen_string_literal: true

# -- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2010-2024 the OpenProject GmbH
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
      class ExportSettingsComponent < BaseExportSettingsComponent
        def current_pdf_export_type
          'table'
        end

        def is_gantt_chart_allowed?
          EnterpriseToken.allows_to?(:gantt_pdf_export)
        end

        def pdf_export_types
          [
            { label: "Table", value: 'table',
              caption: "Export the work packages list in a table with the desired columns." },
            { label: "Report", value: 'report',
              caption: "Export the work package on a detailed report of all work packages in the list." },
            { label: "Gantt chart", value: 'gantt',
              caption: "Export the work packages list in a Gantt diagram view.",
              disabled: !is_gantt_chart_allowed? }
          ]
        end

        def selected_columns
          query
            .columns
            .map { |s| { id: s.name, name: s.caption } }
        end

        def gantt_zoom_levels
          [
            { label: t('js.gantt_chart.zoom.days'), value: 'day', default: true },
            { label: t('js.gantt_chart.zoom.weeks'), value: 'week' },
            { label: t('js.gantt_chart.zoom.months'), value: 'month' },
            { label: t('js.gantt_chart.zoom.quarters'), value: 'quarter' }
          ]
        end

        def gantt_column_widths
          [
            { label: t('js.gantt_chart.export.column_widths.narrow'), value: 'narrow' },
            { label: t('js.gantt_chart.export.column_widths.medium'), value: 'medium', default: true },
            { label: t('js.gantt_chart.export.column_widths.wide'), value: 'wide' },
            { label: t('js.gantt_chart.export.column_widths.very_wide'), value: 'very_wide' }
          ]
        end

        def pdf_paper_sizes
          [
            { label: 'A4', value: 'A4', default: true },
            { label: 'A3', value: 'A3' },
            { label: 'A2', value: 'A2' },
            { label: 'A1', value: 'A1' },
            { label: 'A0', value: 'A0' },
            { label: 'Executive', value: 'EXECUTIVE' },
            { label: 'Folio', value: 'FOLIO' },
            { label: 'Letter', value: 'LETTER' },
            { label: 'Tabloid', value: 'TABLOID' },
          ]
        end
      end
    end
  end
end
