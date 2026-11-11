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

module Import
  module Jiras
    module Validators
      class ServerValidator < HealthReports::ValidatorGroup
        def self.key = :server

        private

        def validate
          register_checks(:reachable, :responds_as_jira)
          check_reachable
          check_responds_as_jira
        end

        def check_reachable
          @server_info = subject.client.server_info
          pass_check(:reachable)
        rescue Import::JiraClient::ConnectionError => e
          fail_check(:reachable, e.reason)
        rescue Import::JiraClient::Error => e
          @server_error = e
          pass_check(:reachable)
        end

        def check_responds_as_jira
          return pass_check(:responds_as_jira) if @server_info.is_a?(Hash) && @server_info.key?("version")
          return fail_check(:responds_as_jira, :not_jira) if @server_error.nil?
          # Jira 10 rejects wrong credentials here, but Jira 8 answers anyway.
          # The authorization group checks the credentials on both.
          return if @server_error.reason == :credentials_rejected

          fail_check(:responds_as_jira, @server_error.reason, context: @server_error.context)
        end
      end
    end
  end
end
