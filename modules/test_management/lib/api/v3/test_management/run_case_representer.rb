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
      class RunCaseRepresenter < ::API::Decorators::Single
        include ::API::Decorators::DateProperty

        link :self do
          { href: api_v3_paths.test_management_run_case(represented.id), title: represented.title }
        end

        link :run do
          { href: api_v3_paths.test_management_run(represented.test_run_id) }
        end

        link :addResult do
          next unless represented.test_run.active? &&
                      (current_user.allowed_in_project?(:execute_test_runs, represented.project) ||
                       current_user.allowed_in_project?(:add_test_runs, represented.project))

          { href: api_v3_paths.test_management_run_case_results(represented.id), method: :post }
        end

        property :id
        property :test_case_id, as: :testCaseId
        property :title
        property :status, getter: ->(*) { effective_status }
        property :assigned_to_id, as: :assigneeId, render_nil: true
        property :results, exec_context: :decorator, getter: ->(*) { result_hashes }
        date_time_property :updated_at

        def result_hashes
          represented.results.map { |result| ResultRepresenter.hash_for(result) }
        end

        def _type
          "TestManagementRunCase"
        end
      end
    end
  end
end
