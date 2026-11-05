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
      class CiTriggerRepresenter < ::API::Decorators::Single
        link :run do
          { href: api_v3_paths.test_management_run(represented.run.id), title: represented.run.name }
        end

        link :iteration do
          { href: api_v3_paths.test_management_run_iteration(represented.run.id, represented.iteration.number) }
        end

        link :connection do
          next unless represented.iteration.connection_id

          { href: api_v3_paths.test_management_ci_connection(represented.iteration.connection_id) }
        end

        property :status
        property :run_id, as: :runId, exec_context: :decorator, getter: ->(*) { represented.run.id }
        property :iteration_id, as: :iterationId, exec_context: :decorator, getter: ->(*) { represented.iteration.id }
        property :iteration_number, as: :iterationNumber, exec_context: :decorator,
                                    getter: ->(*) { represented.iteration.number }
        property :ref
        property :grep
        property :url, render_nil: true
        property :external_id, as: :externalId, render_nil: true
        property :error, render_nil: true
        def _type
          "TestManagementCiTrigger"
        end
      end
    end
  end
end
