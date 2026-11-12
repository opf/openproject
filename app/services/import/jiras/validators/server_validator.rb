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
        SUPPORTED_VERSIONS = Gem::Requirement.new(">= 8.14", "< 12")
        BASIC_AUTH_ONLY_VERSIONS = Gem::Requirement.new("< 9")

        def self.key = :server

        private

        def validate
          register_checks(:reachable, :responds_as_jira, :version_supported, :auth_method_supported)
          check_reachable
          # Jira 10 rejects wrong credentials here, but Jira 8 answers anyway.
          # The authorization group checks the credentials on both.
          return if credentials_rejected?

          check_responds_as_jira
          check_version_supported
          check_auth_method_supported
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

        def credentials_rejected?
          @server_error&.reason == :credentials_rejected
        end

        def check_responds_as_jira
          return pass_check(:responds_as_jira) if @server_info.is_a?(Hash) && @server_info.key?("version")
          return fail_check(:responds_as_jira, :not_jira) if @server_error.nil?

          fail_check(:responds_as_jira, @server_error.reason, context: @server_error.context)
        end

        def check_version_supported
          return warn_check(:version_supported, :unknown_version) if version.nil?
          return pass_check(:version_supported) if SUPPORTED_VERSIONS.satisfied_by?(version)

          warn_check(:version_supported, :unsupported_version, context: { version: version.to_s })
        end

        def check_auth_method_supported
          if subject.auth_method_bearer? && basic_auth_only_version?
            fail_check(:auth_method_supported, :basic_auth_required, context: { version: version.to_s })
          else
            pass_check(:auth_method_supported)
          end
        end

        def basic_auth_only_version?
          version && BASIC_AUTH_ONLY_VERSIONS.satisfied_by?(version)
        end

        def version
          Gem::Version.new(reported_version) if reported_version.present? && Gem::Version.correct?(reported_version)
        end

        def reported_version
          Array(@server_info["versionNumbers"]).join(".").presence || @server_info["version"].to_s
        end
      end
    end
  end
end
