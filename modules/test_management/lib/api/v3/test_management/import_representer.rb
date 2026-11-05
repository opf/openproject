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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module API
  module V3
    module TestManagement
      # One automation upload into a run (counts, unmatched tests, warnings).
      class ImportRepresenter < ::API::Decorators::Single
        include ::API::Decorators::DateProperty

        link :self do
          { href: api_v3_paths.test_management_import(represented.id) }
        end

        link :run do
          next unless represented.test_run_id

          { href: api_v3_paths.test_management_run(represented.test_run_id) }
        end

        link :project do
          { href: api_v3_paths.project(represented.project_id) }
        end

        property :id
        property :format
        property :state
        property :parsed_count, as: :parsedCount
        property :matched_count, as: :matchedCount
        property :created_cases_count, as: :createdCasesCount
        property :unmatched_count, as: :unmatchedCount
        property :unmatched, getter: ->(*) { unmatched_list }
        property :warnings, getter: ->(*) { warnings_list }
        property :digest
        property :external_ref, as: :externalRef, render_nil: true
        property :iteration, exec_context: :decorator, render_nil: true,
                             getter: ->(*) { represented.iteration&.number }
        date_time_property :created_at

        def _type
          "TestManagementAutomationImport"
        end
      end
    end
  end
end
