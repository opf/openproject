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

module ProjectIdentifiers
  module IdentifierAutofix
    class PreviewQuery
      Result = Data.define(:projects_data, :total_count)
      DISPLAY_COUNT = 5

      def call
        analysis = ProblematicIdentifiers.new
        total_count = analysis.count
        projects_data = build_projects_data(analysis)

        Result.new(projects_data:, total_count:)
      end

      private

      def build_projects_data(analysis)
        generate_suggestions(analysis).map do |entry|
          entry.merge(error_reason: analysis.error_reason(entry[:current_identifier]))
        end
      end

      def generate_suggestions(analysis)
        ProjectIdentifierSuggestionGenerator.call(
          preview_projects(analysis.scope),
          exclude: analysis.reserved_identifiers_for_admin_preview.to_set(&:upcase)
        )
      end

      def preview_projects(scope)
        scope
          .select(:id, :name, :identifier)
          .order(:id)
          .limit(DISPLAY_COUNT)
          .to_a
      end
    end
  end
end
