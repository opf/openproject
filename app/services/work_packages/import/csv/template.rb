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
          { key: :one, starts_in: 1, lasts: 4, work: "8", remaining: "8", complete: "0" },
          { key: :two, starts_in: 8, lasts: 1, work: "3.5", remaining: "1.75", complete: "50" }
        ].freeze

        def self.call(project:) = new(project:).call

        def initialize(project:)
          @project = project
        end

        # Excel reads a CSV without a byte order mark as the local code page, which mangles every
        # non-ASCII character in a file we are asking to be handed back to us.
        def call
          "﻿#{body}"
        end

        private

        attr_reader :project

        def body
          ::CSV.generate do |csv|
            csv << headers
            EXAMPLES.each { |example| csv << cells(example) }
          end
        end

        def headers
          columns.map { |attribute| WorkPackage.human_attribute_name(attribute) }
        end

        # Offering a column the parser is configured to reject would hand back a template that
        # fails its own import on the instance that served it.
        def columns
          return HeaderMap::ATTRIBUTES unless WorkPackage.status_based_mode?

          HeaderMap::ATTRIBUTES - HeaderMap::DERIVED_FROM_STATUS
        end

        def cells(example)
          start_date = Date.current + example[:starts_in]

          values = {
            subject: example_text(example, :subject),
            description: example_text(example, :description),
            type: type_name,
            start_date: start_date.iso8601,
            due_date: (start_date + example[:lasts]).iso8601,
            estimated_hours: example[:work],
            remaining_hours: example[:remaining],
            done_ratio: example[:complete]
          }

          columns.map { |attribute| values[attribute] }
        end

        def example_text(example, field)
          I18n.t("work_packages.import.csv.template.examples.#{example[:key]}.#{field}")
        end

        # Naming a type the project does not have would hand back a template that fails its own
        # import on the instance that served it.
        def type_name = @type_name ||= Type.enabled_in(project).pick(:name)
      end
    end
  end
end
