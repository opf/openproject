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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module Storages
  module Adapters
    module Providers
      module Sharepoint
        module Validators
          class StorageConfigurationValidator < HealthReports::ValidatorGroup
            include TaggedLogging

            def self.key = :base_configuration

            private

            def validate
              register_checks :storage_configured,
                              :diagnostic_request,
                              :host,
                              :tenant_id,
                              :client_secret,
                              :client_id

              storage_configuration_status
              diagnostic_request
              check_host
              check_tenant_id
              check_client_secret
              check_client_id
            end

            def storage_configuration_status
              if subject.configured?
                pass_check(:storage_configured)
              else
                fail_check(:storage_configured, :not_configured)
              end
            end

            def diagnostic_request
              if query_result.failure? && query_result.failure.code == :error
                log_unknown_error
                fail_check(:diagnostic_request, :unknown_error)
              else
                pass_check :diagnostic_request
              end
            end

            def check_host
              if subject.host.present?
                pass_check(:host)
              else
                fail_check(:host, :sp_host_missing)
              end
            end

            def check_tenant_id
              return pass_check(:tenant_id) if query_result.success?

              tenant_id_regex = /tenant (?:identifier )?'#{subject.tenant_id}' (?:not found|is neither)/i

              if error_payload[:error] == "invalid_request" && error_payload[:error_description].match?(tenant_id_regex)
                fail_check(:tenant_id, :sp_tenant_id_invalid)
              else
                pass_check(:tenant_id)
              end
            end

            def check_client_id
              return pass_check(:client_id) if query_result.success?

              if error_payload[:error] == "unauthorized_client"
                fail_check(:client_id, :client_id_invalid)
              else
                pass_check(:client_id)
              end
            end

            def check_client_secret
              return pass_check(:client_secret) if query_result.success?

              if error_payload[:error] == "invalid_client"
                fail_check(:client_secret, :client_secret_invalid)
              else
                pass_check(:client_secret)
              end
            end

            def query_result
              @query_result ||= Input::Files.build(folder: "/").bind do |input_data|
                Registry["#{subject}.queries.files"].call(storage: subject, auth_strategy:, input_data:)
              end
            end

            def log_unknown_error
              error "Connection validation failed with unknown error:\n" \
                    "\tstorage: ##{subject.id} #{subject.name}\n" \
                    "\tstatus: #{query_result.failure}\n" \
                    "\tresponse: #{query_result.failure.payload}"
            end

            def auth_strategy = Registry["sharepoint.authentication.userless"].call

            def error_payload
              @error_payload ||= query_result.either(->(_) { {} }, -> { MultiJson.load(it.payload, symbolize_keys: true) })
            end
          end
        end
      end
    end
  end
end
