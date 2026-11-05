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

module TestManagement
  module CiTriggers
    module Dispatchers
      class Github < Base
        protected

        def dispatch(ref:, inputs:)
          url = "#{base_url}/repos/#{repository}/actions/workflows/#{enc(connection.workflow)}/dispatches"
          response = post(url, json: { ref:, inputs:, return_run_details: true },
                               headers: { "Authorization" => "Bearer #{token}",
                                          "Accept" => "application/vnd.github+json" })
          case code(response)
          when 200
            details = json(response)
            triggered(url: details["html_url"] || workflow_url, external_id: details["workflow_run_id"])
          when 204 then triggered(url: workflow_url)
          else http_failure(response)
          end
        end

        private

        def workflow_url = "#{connection.repository_url}/actions/workflows/#{enc(connection.workflow)}"
      end
    end
  end
end
