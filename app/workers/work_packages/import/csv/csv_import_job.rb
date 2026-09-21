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

module WorkPackages
  module Import
    module CSV
      class CsvImportJob < ApplicationJob
        queue_with_priority :above_normal

        PROBLEM_LIMIT = 500

        SUCCESSFUL = %w[checked imported].freeze

        def perform(user:, project:, attachment_id:, dry_run:)
          @user = user
          @project = project
          @dry_run = dry_run
          @attachment = Attachment.find_by(id: attachment_id, container: nil, author: user)

          @started_at = Time.current

          User.execute_as(user) { run }
        ensure
          discard_attachment unless outcome == "checked"
        end

        def store_status? = true

        def updates_own_status? = true

        def title
          I18n.t("work_packages.import.csv.job.#{dry_run ? :checking : :importing}")
        end

        private

        attr_reader :user, :project, :attachment, :outcome, :started_at

        def dry_run
          @dry_run.nil? ? queued[:dry_run] : @dry_run
        end

        # The queued and started statuses are written before #perform, and the page will not show a
        # report it cannot tie to the project in the route, so the identity goes in from the first
        # write rather than only with the result.
        def build_status_attributes(attributes)
          super.tap do |attrs|
            attrs[:payload] = identity.merge(attrs[:payload] || {})
          end
        end

        # What the page needs to show a queued run: which project it belongs to, so the report is
        # tied to the route, which file it is working through, and whether it will create anything.
        def identity
          @identity ||= {
            project_id: (@project || queued[:project])&.id,
            filename: (attachment || Attachment.find_by(id: queued[:attachment_id]))&.filename,
            dry_run:
          }
        end

        def queued = arguments.first.to_h

        def discard_attachment
          Attachment.where(id: attachment&.id, container: nil, author: user).destroy_all
        end

        def run
          return reject(file_problem(:expired)) if attachment.nil?

          parse_and_import
        rescue ::CSV::MalformedCSVError => e
          reject(file_problem(:malformed, line: e.line_number))
        end

        def parse_and_import
          parsed = Parser.call(attachment.local_path)

          return finish(:file_rejected, column_problems: problems(parsed.result)) if parsed.failure?

          report(ImportService.new(user:, project:).call(rows: parsed.result, dry_run:))
        end

        def reject(problem)
          finish(:file_rejected, column_problems: problems([problem]))
        end

        def report(result)
          outcome = if result.failure?
                      :rows_rejected
                    else
                      dry_run ? :checked : :imported
                    end

          finish(outcome, **report_payload(result.result))
        end

        def report_payload(report)
          {
            row_count: report.row_count,
            created_count: report.created_count,
            back_dated: report.back_dated.positive?,
            assignee_count: report.assignee_count,
            dated_count: report.dated_count,
            counts: report.counts,
            problems: problems(report.problems),
            problems_omitted: [report.problems.size - PROBLEM_LIMIT, 0].max,
            available: report.available
          }
        end

        def finish(outcome, **payload)
          @outcome = outcome.to_s

          upsert_status status: SUCCESSFUL.include?(@outcome) ? :success : :failure,
                        payload: base_payload.merge(outcome: @outcome, **payload)
        end

        def base_payload
          {
            project_id: project.id,
            filename: attachment&.filename,
            attachment_id: attachment&.id,
            dry_run:,
            row_count: 0,
            created_count: 0,
            back_dated: false,
            assignee_count: 0,
            dated_count: 0,
            started_at: started_at,
            finished_at: Time.current,
            counts: {},
            problems: [],
            problems_omitted: 0,
            column_problems: [],
            available: {}
          }
        end

        def problems(list) = list.first(PROBLEM_LIMIT).map(&:to_h)

        def file_problem(key, **)
          HeaderMap::Problem.new(column: nil,
                                 header: nil,
                                 message: I18n.t("work_packages.import.csv.file.#{key}", **))
        end
      end
    end
  end
end
