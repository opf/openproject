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

module Admin::Import::Jira
  class ConnectionCheckDialogComponent < ApplicationComponent
    alias_method :report, :model

    def initialize(health_report_id:)
      report = HealthReport.find(health_report_id)

      super(report)
    end

    private

    def title
      I18n.t("admin.jira.connection_check.dialog.failure.title")
    end

    def description
      t("admin.jira.connection_check.dialog.failure.description_html", check: check_label)
    end

    def check_label
      group = report.results.find(&:failure?)
      result = group.results.find(&:failure?)
      I18n.t("admin.jira.connection_check.#{group.key}.#{result.key}")
    end
  end
end
