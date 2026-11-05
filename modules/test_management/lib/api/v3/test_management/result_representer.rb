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
      class ResultRepresenter < ::API::Decorators::Single
        include ::API::Decorators::DateProperty

        link :self do
          { href: api_v3_paths.test_management_result(represented.id) }
        end

        link :runCase do
          { href: api_v3_paths.test_management_run_case(represented.run_case_id) }
        end

        property :id
        property :status
        property :source
        property :comment, render_nil: true
        property :error_message, as: :errorMessage, render_nil: true
        property :error_trace, as: :errorTrace, render_nil: true
        property :duration_ms, as: :durationMs, render_nil: true
        property :external_id, as: :externalId, render_nil: false
        property :import_id, as: :importId, render_nil: false
        property :iteration_number, as: :iteration, exec_context: :decorator, getter: ->(*) {
          represented.iteration&.number
        }, render_nil: true
        property :user_name, as: :userName, exec_context: :decorator, getter: ->(*) { represented.user&.name }, render_nil: true
        date_time_property :created_at

        def self.hash_for(result)
          {
            id: result.id, status: result.status, source: result.source, comment: result.comment,
            durationMs: result.duration_ms, externalId: result.external_id, importId: result.import_id,
            details: result.details_hash.slice("projectName", "retry", "flaky", "ciRunUrl"),
            errorMessage: result.error_message, errorTrace: result.error_trace,
            createdAt: result.created_at&.utc&.iso8601
          }.compact
        end

        def _type
          "TestManagementResult"
        end
      end
    end
  end
end
