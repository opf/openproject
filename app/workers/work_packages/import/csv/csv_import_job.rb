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
          @attachment = Attachment.find_by(id: attachment_id)

          User.execute_as(user) { run }
        ensure
          # Not destroy!: raising here would mask whatever the job was already failing with.
          attachment&.destroy unless outcome == "checked" # rubocop:disable Rails/SaveBang
        end

        def store_status? = true

        def updates_own_status? = true

        def title
          I18n.t("work_packages.import.csv.job.#{dry_run ? :checking : :importing}")
        end

        private

        attr_reader :user, :project, :attachment, :outcome

        def dry_run
          @dry_run.nil? ? arguments.first.to_h[:dry_run] : @dry_run
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
            counts: report.counts,
            problems: problems(report.problems),
            problems_omitted: [report.problems.size - PROBLEM_LIMIT, 0].max
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
            dry_run:
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
