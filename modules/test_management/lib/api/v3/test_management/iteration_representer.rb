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
      # One iteration (execution) of a test run. statusCounts / passRate use the last result
      # of every run case within the iteration; for the current iteration they equal the run's.
      class IterationRepresenter < ::API::Decorators::Single
        include ::API::Decorators::DateProperty

        link :self do
          { href: api_v3_paths.test_management_run_iteration(represented.test_run_id, represented.number),
            title: represented.display_name }
        end

        link :run do
          { href: api_v3_paths.test_management_run(represented.test_run_id) }
        end

        link :connection do
          next unless represented.connection_id

          { href: api_v3_paths.test_management_ci_connection(represented.connection_id) }
        end

        property :id
        property :number
        property :name, getter: ->(*) { display_name }
        property :source
        property :current, exec_context: :decorator, getter: ->(*) { current? }
        property :external_ref, as: :externalRef, render_nil: true
        property :ci, getter: ->(*) { ci_info }
        property :status_counts, as: :statusCounts, exec_context: :decorator, getter: ->(*) { status_counts }
        property :total_cases, as: :totalCases, exec_context: :decorator, getter: ->(*) { status_counts.values.sum }
        property :pass_rate, as: :passRate, exec_context: :decorator,
                             getter: ->(*) { ::TestManagement::TestRun.pass_rate(status_counts) }
        date_time_property :created_at

        def initialize(model, current_user:, embed_links: false, current_number: nil)
          @current_number = current_number
          super(model, current_user:, embed_links:)
        end

        def current?
          return represented.preloaded_current unless represented.preloaded_current.nil?

          @current_number ||= represented.test_run.iterations.maximum(:number)
          represented.number == @current_number
        end

        def status_counts
          @status_counts ||= represented.preloaded_status_counts ||
                             (current? ? represented.test_run.status_counts : represented.status_counts)
        end

        def _type
          "TestManagementRunIteration"
        end
      end
    end
  end
end
