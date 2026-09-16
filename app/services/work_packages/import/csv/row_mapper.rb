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
      class RowMapper
        Problem = Data.define(:row, :attribute, :value, :message)

        Mapped = Data.define(:attributes, :timestamps)

        TIMESTAMPS = %i[created_at updated_at].freeze

        PROJECT_SCOPED = %i[type category].freeze

        class Unresolvable < StandardError; end
        private_constant :Unresolvable

        def initialize(project:)
          @project = project
        end

        def prime(rows)
          mails = unresolved_mails(rows)
          return if mails.empty?

          found = User.active.where("LOWER(mail) IN (?)", mails).index_by { |user| user.mail.downcase }
          mails.each { |mail| users[mail] = found[mail] }
        end

        def call(row)
          problems = carried_problems(row)
          resolved = {}

          row.values.each_pair do |attribute, raw|
            next if raw.blank?

            begin
              resolved[attribute] = resolve(attribute, raw)
            rescue Unresolvable => e
              problems << problem(row, attribute, raw, e.message)
            end
          end

          return ServiceResult.failure(result: problems) if problems.any?

          ServiceResult.success(result: mapped(resolved))
        end

        private

        attr_reader :project

        def carried_problems(row)
          row.problems.map { |message| Problem.new(row: row.number, attribute: nil, value: nil, message:) }
        end

        def mapped(resolved)
          timestamps, attributes = resolved.partition { |attribute, _| TIMESTAMPS.include?(attribute) }

          Mapped.new(attributes: attributes.to_h, timestamps: timestamps.to_h)
        end

        def problem(row, attribute, raw, message)
          Problem.new(row: row.number,
                      attribute: WorkPackage.human_attribute_name(attribute),
                      value: raw,
                      message:)
        end

        def resolve(attribute, raw)
          case attribute
          when :type, :status, :priority, :category then named(attribute, raw)
          when :assigned_to then user(raw)
          when :start_date, :due_date then date(raw)
          when :created_at, :updated_at then timestamp(raw)
          when :done_ratio then percentage(raw)
          else raw
          end
        end

        def named(attribute, raw)
          index(attribute).fetch(raw.strip.downcase) { raise Unresolvable, unknown_message(attribute) }
        end

        def index(attribute)
          indexes[attribute] ||= by_name(scope_for(attribute))
        end

        def scope_for(attribute)
          case attribute
          when :type then Type.enabled_in(project)
          when :status then Status.all
          when :priority then IssuePriority.active
          when :category then project.categories
          end
        end

        def unknown_message(attribute)
          unknown_messages[attribute] ||=
            I18n.t("work_packages.import.csv.row.#{PROJECT_SCOPED.include?(attribute) ? :unknown_in_project : :unknown}",
                   available: index(attribute).values.map(&:name).join(", ")).freeze
        end

        def user(raw)
          mail = normalized_mail(raw)

          users.fetch(mail) { users[mail] = User.active.find_by("LOWER(mail) = ?", mail) } ||
            unresolvable(:unknown_user)
        end

        def normalized_mail(raw) = raw.presence&.strip&.downcase.presence

        def unresolved_mails(rows)
          rows.filter_map { |row| normalized_mail(row.values[:assigned_to]) }.uniq - users.keys
        end

        def date(raw)
          Date.iso8601(raw.strip)
        rescue Date::Error
          unresolvable(:invalid_date)
        end

        def timestamp(raw)
          Time.iso8601(raw.strip)
        rescue ArgumentError
          unresolvable(:invalid_timestamp)
        end

        def percentage(raw)
          parsed = PercentageConverter.parse(raw) if PercentageConverter.valid?(raw)
          unresolvable(:fractional_percentage) if parsed && parsed != parsed.to_i

          raw
        end

        def unresolvable(key, **)
          raise Unresolvable, I18n.t("work_packages.import.csv.row.#{key}", **)
        end

        def indexes = @indexes ||= {}

        def unknown_messages = @unknown_messages ||= {}

        def users = @users ||= {}

        def by_name(scope) = scope.index_by { |record| record.name.strip.downcase }
      end
    end
  end
end
