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

require "active_storage/filename"

class CostReports::XLS::ExportJob < Exports::ExportJob
  self.model = ::CostReport

  def project
    options[:project]
  end

  def cost_types
    options[:cost_types]
  end

  def title
    I18n.t("export.cost_reports.title")
  end

  private

  def prepare!
    CostQuery::Cache.check
    self.query = ::CostReports::ParamsToReport.new(query, project:, user: current_user).call
    # The export is a flat list of entries, so the report's grouping is dropped:
    # a grouped query aggregates in SQL and no longer yields the single entries.
    query.apply_pivot_configuration(rows: [], columns: [])
  end

  def export!
    handle_export_result(export, xls_report_result)
  end

  def xls_report_result
    params = { query:, project:, cost_types: }
    content = ::OpenProject::Reporting::CostEntryXlsTable.generate(params).xls
    time = Time.current.strftime("%Y-%m-%d-T-%H-%M-%S")
    export_title = "cost-report-#{time}.xls"

    ::Exports::Result.new(format: :xls,
                          title: export_title,
                          mime_type: "application/vnd.ms-excel",
                          content:)
  end
end
