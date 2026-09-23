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
      class ImportService
        include Redmine::I18n

        Report = Data.define(:row_count, :created_count, :query_id, :assignee_count, :dated_count,
                             :counts, :problems, :available, :created_ids)

        COUNTED = %i[type status priority category].freeze

        Progress = Struct.new(:created_count, :counts, :problems, :assignees, :dated, :created_ids)
        private_constant :Progress

        def initialize(user:, project:)
          @user = user
          @project = project
        end

        def call(rows:, dry_run: false)
          report = nil

          WorkPackage.transaction do
            report = silently { import(rows) }

            raise ActiveRecord::Rollback if incomplete?(report) || dry_run

            report = report.with(query_id: saved_view(report.created_ids))
          end

          incomplete?(report) ? ServiceResult.failure(result: report) : ServiceResult.success(result: report)
        end

        private

        attr_reader :user, :project

        def incomplete?(report)
          report.problems.any? || report.created_count != report.row_count
        end

        def silently(&)
          Journal::NotificationConfiguration.with(false) do
            Journal::EventConfiguration.with(false, &)
          end
        end

        def import(rows)
          mapper = RowMapper.new(project:)
          mapper.prime(rows)

          progress = Progress.new(0, {}, [], Set.new, 0, [])
          rows.each { |row| import_row(row, mapper, progress) }

          report(rows.size, progress, mapper.available)
        end

        def report(row_count, progress, available)
          Report.new(row_count:,
                     created_count: progress.created_count,
                     query_id: nil,
                     assignee_count: progress.assignees.size,
                     dated_count: progress.dated,
                     counts: progress.counts,
                     problems: progress.problems,
                     available:,
                     created_ids: progress.created_ids)
        end

        def import_row(row, mapper, progress)
          mapped = mapper.call(row)
          return progress.problems.concat(mapped.result) if mapped.failure?

          record(create_work_package(mapped.result.attributes), row, mapped.result.timestamps, progress)
        end

        def record(created, row, timestamps, progress)
          if created.success?
            progress.created_count += 1
            progress.created_ids << created.result.id
            back_date(created.result, timestamps)
            summarise(progress, created.result)
          else
            progress.problems.concat(problems_for(row, created.errors))
          end
        end

        def back_date(work_package, timestamps)
          return if timestamps.empty?

          work_package.update_columns(timestamps)
          back_date_creation_journal(work_package, timestamps[:created_at])
        end

        def back_date_creation_journal(work_package, created_at)
          return if created_at.nil?

          work_package.journals.first&.update_columns(created_at:,
                                                      updated_at: created_at,
                                                      validity_period: (created_at..))
        end

        def create_work_package(attributes)
          WorkPackages::CreateService.new(user:).call(project:, **attributes)
        end

        def saved_view(ids)
          query = Query.new(name: view_name, project:, user:, public: false, include_subprojects: false)
          query.add_filter("id", "=", ids.map(&:to_s))

          User.execute_as(user) do
            next unless query.save

            View.create!(query:, type: "work_packages_table")
            query.id
          end
        end

        def view_name = I18n.t("work_packages.import.csv.view_name", datetime: format_time(Time.current))

        def summarise(progress, work_package)
          count_values(progress.counts, work_package)
          progress.assignees << work_package.assigned_to_id if work_package.assigned_to_id
          progress.dated += 1 if work_package.start_date || work_package.due_date
        end

        def count_values(counts, work_package)
          COUNTED.each do |attribute|
            name = work_package.public_send(attribute)&.name
            next if name.nil?

            per_value = (counts[attribute.to_s] ||= {})
            per_value[name] = per_value.fetch(name, 0) + 1
          end
        end

        def problems_for(row, errors)
          problems = contract_problems(row, errors)

          problems.presence || [unexplained(row)]
        end

        def unexplained(row)
          RowMapper::Problem.new(row: row.number,
                                 attribute: nil,
                                 value: nil,
                                 message: I18n.t("work_packages.import.csv.row.not_created"))
        end

        def contract_problems(row, errors)
          errors.map do |error|
            attribute = csv_attribute(error.attribute)

            RowMapper::Problem.new(row: row.number,
                                   attribute: attribute&.to_s,
                                   value: attribute && row.values[attribute],
                                   message: attribute ? error.message : error.full_message)
          end
        end

        def csv_attribute(name)
          candidate = name.to_s.delete_suffix("_id").to_sym
          candidate if HeaderMap::ATTRIBUTES.include?(candidate)
        end
      end
    end
  end
end
