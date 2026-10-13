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

module Llm
  # The downloadable health report. It is pasted into support tickets, so it
  # must not contain the API key or the custom headers: a gateway header
  # routinely carries a second credential.
  class HealthReportMarkdown
    STATUS = { success: :passed, failure: :failed, warning: :warning, skipped: :skipped }.freeze

    def initialize(connection, report)
      @connection = connection
      @report = report
    end

    def to_s
      [heading, settings, *report.results.map { |group| checks(group) }].join("\n\n").concat("\n")
    end

    private

    attr_reader :connection, :report

    def heading
      ["# #{t('report.title')}",
       "",
       "- #{t('report.connection')}: #{literal(connection.identifier)}",
       "- #{t('report.checked_at')}: #{report.created_at.utc.iso8601}"].join("\n")
    end

    def settings
      rows = connection.non_confidential_configuration.map { |key, value| "| #{key} | #{cell(value)} |" }

      ["## #{t('report.settings')}",
       "",
       "| #{t('report.setting')} | #{t('report.value')} |",
       "| --- | --- |",
       *rows].join("\n")
    end

    def checks(group)
      ["## #{t("#{group.key}.header")}", "", *group.results.map { |result| check(group, result) }].join("\n")
    end

    def check(group, result)
      line = "- **#{t("#{group.key}.#{result.key}")}**: #{status(result)}"
      return line if result.code.nil?

      "#{line} (`#{result.code.to_s.upcase}`). #{t("errors.#{result.code}", **literals(result.context))}"
    end

    def status(result)
      I18n.t(STATUS.fetch(result.state), scope: "health_reports.result_component.status")
    end

    def cell(value) = literal(value).gsub("|", "\\|")

    def literals(context) = context.to_h.symbolize_keys.transform_values { |value| literal(value) }

    # Values such as model identifiers come from the server. Inside a code span
    # nothing in them is rendered.
    def literal(value)
      text = value.to_s.gsub(/\s+/, " ").delete("`").strip

      text.empty? ? "" : "`#{text}`"
    end

    def t(key, **) = I18n.t(key, scope: "llm.health_checks", **)
  end
end
