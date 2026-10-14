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
      class Template
        FILENAME = "work-packages-import-template.csv"

        EXAMPLES = [
          { key: :one, starts_in: 1, lasts: 4, work: "8", remaining: "8", complete: "0",
            created_days_ago: 14, updated_days_ago: 2 },
          { key: :two, starts_in: 8, lasts: 1, work: "3.5", remaining: "1.75", complete: "50",
            created_days_ago: 3, updated_days_ago: 1 }
        ].freeze

        def self.call(project:, user:) = new(project:, user:).call

        def initialize(project:, user:)
          @project = project
          @user = user
        end

        # Excel reads a CSV without a byte order mark as the local code page, which mangles every
        # non-ASCII character in a file we are asking to be handed back to us.
        def call
          "﻿#{body}"
        end

        private

        attr_reader :project, :user

        def body
          ::CSV.generate do |csv|
            csv << headers
            EXAMPLES.each { |example| csv << cells(example) }
          end
        end

        def headers
          columns.map { |attribute| WorkPackage.human_attribute_name(attribute) }
        end

        def columns
          return HeaderMap::ATTRIBUTES unless WorkPackage.status_based_mode?

          HeaderMap::ATTRIBUTES - HeaderMap::DERIVED_FROM_STATUS
        end

        def cells(example)
          values = text(example).merge(named, people, dates(example), progress(example))

          columns.map { |attribute| values[attribute] }
        end

        def text(example)
          { subject: example_text(example, :subject),
            description: example_text(example, :description) }
        end

        def named
          { type: type_name,
            status: status_name,
            priority: priority_name,
            category: category_name,
            version: version_name }
        end

        def people
          { assigned_to: assignee_mail,
            responsible: assignee_mail,
            author: author_mail }
        end

        def dates(example)
          start_date = Date.current + example[:starts_in]

          { start_date: start_date.iso8601,
            due_date: (start_date + example[:lasts]).iso8601,
            created_at: timestamp(example[:created_days_ago]),
            updated_at: timestamp(example[:updated_days_ago]) }
        end

        def progress(example)
          { estimated_hours: example[:work],
            remaining_hours: example[:remaining],
            done_ratio: example[:complete] }
        end

        def example_text(example, field)
          I18n.t("work_packages.import.csv.template.examples.#{example[:key]}.#{field}")
        end

        def timestamp(days_ago) = days_ago.days.ago.utc.change(usec: 0).iso8601

        def type_name = @type_name ||= Type.enabled_in(project).pick(:name)

        def status_name = @status_name ||= (Status.default || Status.order_by_position.first)&.name

        def priority_name = @priority_name ||= (IssuePriority.default || IssuePriority.active.first)&.name

        # A project holding no categories or versions leaves the column empty: naming one it does
        # not have would hand back a template that cannot be imported.
        def category_name = @category_name ||= project.categories.pick(:name)

        def version_name = @version_name ||= project.assignable_versions.first&.name

        def author_mail = @author_mail ||= user&.mail.presence

        # The project decides who may be assigned, so the example names the person downloading it
        # only where the project would accept them.
        def assignee_mail
          @assignee_mail ||= assignable.where(id: user).pick(:mail) || assignable.pick(:mail)
        end

        def assignable = User.not_builtin.possible_assignee(project).ordered_by_name
      end
    end
  end
end
