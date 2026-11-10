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

module LlmConnections
  class DisconnectService
    def initialize(connection)
      @connection = connection
    end

    def call
      result = OpenProject::Mutex.with_advisory_lock_transaction(connection) do
        next ServiceResult.failure(result: connection) if connection.reload.configured_from_env?

        clear_api_key
        Setting.llm_features_enabled = false if Setting.llm_features_enabled_writable?
        ServiceResult.success(result: connection)
      end

      Llm::HealthCheckJob.toggle_cron_job if result.success?
      result
    end

    private

    attr_reader :connection

    def clear_api_key
      connection.update_columns(api_key: nil, env_provisioned_at: nil, env_fingerprint: nil, updated_at: Time.current)
    end
  end
end
