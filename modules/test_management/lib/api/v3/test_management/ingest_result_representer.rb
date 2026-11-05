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
      # Response of an ingest: the import summary plus the run it reported into.
      class IngestResultRepresenter < ::API::Decorators::Single
        link :self do
          { href: api_v3_paths.test_management_import(represented.import.id) }
        end

        link :run do
          { href: api_v3_paths.test_management_run(represented.run.id), title: represented.run.name }
        end

        link :iteration do
          next unless represented.iteration

          { href: api_v3_paths.test_management_run_iteration(represented.run.id, represented.iteration.number) }
        end

        link :connection do
          next unless represented.connection

          { href: api_v3_paths.test_management_ci_connection(represented.connection.id), title: represented.connection.name }
        end

        property :created_run, as: :createdRun, getter: ->(*) { created_run? }
        property :created_iteration, as: :createdIteration, getter: ->(*) { created_iteration? }
        property :mode
        property :iteration, exec_context: :decorator, render_nil: true,
                             getter: ->(*) {
                               iteration = represented.iteration
                               iteration && { id: iteration.id, number: iteration.number, name: iteration.display_name }
                             }
        property :replay, getter: ->(*) { replay? }
        property :import, exec_context: :decorator,
                          getter: ->(*) { ImportRepresenter.new(represented.import, current_user:).to_hash }
        property :run, exec_context: :decorator,
                       getter: ->(*) { RunRepresenter.new(represented.run.reload, current_user:).to_hash }

        def _type
          "TestManagementIngestResult"
        end
      end
    end
  end
end
