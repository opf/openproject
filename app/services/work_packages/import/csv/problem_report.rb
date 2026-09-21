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
      class ProblemReport
        ROW_FIELDS = %w[row attribute value message available].freeze
        COLUMN_FIELDS = %w[column header message].freeze

        def self.call(payload:) = new(payload:).call

        def initialize(payload:)
          @payload = payload
        end

        def call
          "﻿#{body}"
        end

        private

        attr_reader :payload

        def body
          ::CSV.generate do |csv|
            csv << fields.map { |field| I18n.t("work_packages.import.report.table.#{field}") }
            problems.each { |problem| csv << fields.map { |field| cell(problem, field) } }
          end
        end

        def cell(problem, field)
          case field
          when "attribute" then problem[field].presence && WorkPackage.human_attribute_name(problem[field])
          when "available" then available_for(problem)&.join(", ")
          else problem[field]
          end
        end

        def available_for(problem) = payload.dig("available", problem["attribute"].to_s)

        def problems = @problems ||= payload["problems"].presence || payload["column_problems"].to_a

        def fields = payload["problems"].present? ? ROW_FIELDS : COLUMN_FIELDS
      end
    end
  end
end
