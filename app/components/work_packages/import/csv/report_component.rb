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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module WorkPackages
  module Import
    module CSV
      class ReportComponent < ApplicationComponent
        include ApplicationHelper
        include OpPrimer::ComponentHelpers

        def initialize(status:, project:)
          super(status)
          @status = status
          @project = project
        end

        private

        attr_reader :status, :project

        def payload = status.payload

        def outcome = payload["outcome"]

        def filename = payload["filename"]

        def row_count = payload["row_count"].to_i

        def created_count = payload["created_count"].to_i

        def problems = payload["problems"].to_a

        def column_problems = payload["column_problems"].to_a

        # A problem about the file as a whole names neither a column nor a header, so there is
        # nothing to tabulate: the message is the whole report.
        def file_problems = column_problems.select { |problem| problem["column"].blank? && problem["header"].blank? }

        def header_problems = column_problems - file_problems

        def file_banner
          Primer::Alpha::Banner
            .new(scheme: :danger,
                 dismiss_scheme: :none,
                 mb: 3,
                 description: t("work_packages.import.report.file_rejected.nothing"))
            .with_content(file_problems.pluck("message").join(" "))
        end

        def problems_omitted = payload["problems_omitted"].to_i

        def problem_count = problems.size + problems_omitted

        def rejected_lines = problems.filter_map { |problem| problem["row"] }.uniq.size

        def headline_counts
          [[created_count, :work_packages],
           [type_counts.size, :types],
           [payload["assignee_count"].to_i, :assignees],
           [payload["dated_count"].to_i, :dated]]
        end

        # The payload keys the counts by attribute rather than by caption, so a run started in one
        # language can be read in another.
        def breakdown
          ImportService::COUNTED.filter_map do |attribute|
            values = payload.dig("counts", attribute.to_s)
            [WorkPackage.human_attribute_name(attribute), values] if values.present?
          end
        end

        def type_counts = payload.dig("counts", "type").to_h

        def row_headers
          %i[row attribute value message].map { |key| t("work_packages.import.report.table.#{key}") }
        end

        def column_headers
          %i[column header message].map { |key| t("work_packages.import.report.table.#{key}") }
        end

        def row_problems
          problems.map do |problem|
            [{ text: problem["row"], style: :muted },
             { text: caption(problem["attribute"]), style: :strong },
             { text: problem["value"], style: :code },
             { text: problem["message"], available: available_for(problem), style: :message }]
          end
        end

        def column_problem_rows
          header_problems.map do |problem|
            [{ text: problem["column"], style: :muted },
             { text: problem["header"], style: :code },
             { text: problem["message"], available: problem["available"], style: :message }]
          end
        end

        def caption(attribute) = attribute.presence && WorkPackage.human_attribute_name(attribute)

        # One list per attribute on the report, rather than a copy on every problem explaining it.
        def available_for(problem) = payload.dig("available", problem["attribute"].to_s)

        def shown_count
          if problems_omitted.positive?
            t("work_packages.import.report.problems.capped", count: problem_count, shown: problems.size)
          else
            t("work_packages.import.report.problems.all", count: problem_count)
          end
        end

        def header_line
          t("work_packages.import.report.file_rejected.line", filename:)
        end

        def stat_cards
          headline_counts.map do |number, key|
            Users::WorkingHours::StatCardComponent.new(
              label: t("work_packages.import.report.headline.#{key}.label"),
              value: number_with_delimiter(number),
              subtitle: t("work_packages.import.report.headline.#{key}.subtitle")
            )
          end
        end

        def created_stats
          [[created_count, t("work_packages.import.report.imported.work_packages")]] +
            type_counts.map { |name, count| [count, name] }
        end

        def imported_banner
          Primer::Alpha::Banner
            .new(scheme: :success, dismiss_scheme: :none, mb: 3, description: imported_description)
            .with_content(t("work_packages.import.report.imported.title", count: created_count))
        end

        def imported_description
          t("work_packages.import.report.imported.text_html",
            filename: content_tag(:code, filename),
            date: helpers.format_date(finished_at),
            time: helpers.format_time(finished_at, include_date: false))
        end

        def finished_at = @finished_at ||= Time.zone.parse(payload["finished_at"].to_s)

        def created_list_button
          Primer::Beta::Button.new(tag: :a, href: created_list_path, scheme: :primary, mr: 2)
        end

        def banner(scheme, outcome, **counts)
          Primer::Alpha::Banner
            .new(scheme:,
                 dismiss_scheme: :none,
                 mb: 3,
                 description: t("work_packages.import.report.#{outcome}.text"))
            .with_content(t("work_packages.import.report.#{outcome}.title", **counts))
        end

        # A real link, so it survives without JavaScript, but handled in place: resetting two
        # regions does not need a page visit, and a visit re-bootstraps everything around them.
        def clear_button
          Primer::Beta::Button.new(tag: :a,
                                   href: import_project_work_packages_path(project),
                                   data: { action: "work-packages--csv-import#clear",
                                           stream_url: import_status_project_work_packages_path(project) })
        end

        def import_path = import_project_work_packages_path(project)

        def problems_path = import_problems_project_work_packages_path(project, job: status.job_id)

        # A back-dated run puts created_at outside the window the filter asks about, so the link
        # would quietly list fewer work packages than were created.
        def created_list_path
          return if payload["back_dated"] || payload["started_at"].blank?

          project_work_packages_path(project, query_props: created_query.to_json)
        end

        def created_query
          {
            c: %w[id type subject status assignee startDate dueDate],
            t: "id:asc",
            f: [{ n: "createdAt", o: "<>d", v: [payload["started_at"], payload["finished_at"]] },
                { n: "author", o: "=", v: [status.user_id.to_s] }]
          }
        end
      end
    end
  end
end
