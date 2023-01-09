#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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

require 'spec_helper'
require_relative '../../../support/storage_server_helpers'

shared_examples_for 'storage contract', :storage_server_helpers, webmock: true do
  # Only admins have the right to create/delete storages.
  let(:current_user) { create(:admin) }
  let(:storage_name) { 'Storage 1' }
  let(:storage_provider_type) { Storages::Storage::PROVIDER_TYPE_NEXTCLOUD }
  let(:storage_host) { 'https://host1.example.com' }
  let(:storage_creator) { current_user }

  before do
    if storage_host.present?
      mock_server_capabilities_response(storage_host)
      mock_server_config_check_response(storage_host)
    end
  end

  it_behaves_like 'contract is valid for active admins and invalid for regular users'

  describe 'validations' do
    context 'when all attributes are valid' do
      include_examples 'contract is valid'
    end

    context 'when name is invalid' do
      context 'as it is too long' do
        let(:storage_name) { 'X' * 257 }

        include_examples 'contract is invalid', name: :too_long
      end

      context 'as it is empty' do
        let(:storage_name) { '' }

        include_examples 'contract is invalid', name: :blank
      end

      context 'as it is nil' do
        let(:storage_name) { nil }

        include_examples 'contract is invalid', name: :blank
      end
    end

    context 'when provider_type is invalid' do
      context 'as it is unknown' do
        let(:storage_provider_type) { 'unknown_provider_type' }

        include_examples 'contract is invalid', provider_type: :inclusion
      end

      context 'as it is empty' do
        let(:storage_provider_type) { '' }

        include_examples 'contract is invalid', provider_type: :inclusion
      end

      context 'as it is nil' do
        let(:storage_provider_type) { nil }

        include_examples 'contract is invalid', provider_type: :inclusion
      end
    end

    context 'when host is invalid' do
      context 'as host is not a URL' do
        let(:storage_host) { '---invalid-url---' }

        include_examples 'contract is invalid', host: I18n.t('activerecord.errors.messages.invalid_url')
      end

      context 'as host is an empty string' do
        let(:storage_host) { '' }

        include_examples 'contract is invalid', host: I18n.t('activerecord.errors.messages.invalid_url')
      end

      context 'as host is longer than 255' do
        let(:storage_host) { "http://#{'a' * 250}.com" }

        include_examples 'contract is invalid', host: :too_long
      end

      context 'as host is nil' do
        let(:storage_host) { nil }

        include_examples 'contract is invalid', host: :url
      end

      context 'when host is an unsafe IP' do
        let(:storage_host) { 'http://172.16.193.146' }

        include_examples 'contract is invalid', host: :url_not_secure_context
      end

      context 'when host is an unsafe hostname' do
        let(:storage_host) { 'http://nc.openproject.com' }

        include_examples 'contract is invalid', host: :url_not_secure_context
      end

      context 'when provider_type is nextcloud' do
        let(:capabilities_response_body) { nil } # use default
        let(:capabilities_response_code) { nil } # use default
        let(:capabilities_response_headers) { nil } # use default
        let(:capabilities_response_major_version) { 22 }
        let(:check_config_response_body) { nil } # use default
        let(:check_config_response_code) { nil } # use default
        let(:check_config_response_headers) { nil } # use default

        before do
          # simulate host value changed to have GET request sent to check host URL validity
          storage.host_will_change!

          # simulate http response returned upon GET request
          mock_server_capabilities_response(storage_host,
                                            response_code: capabilities_response_code,
                                            response_headers: capabilities_response_headers,
                                            response_body: capabilities_response_body,
                                            response_nextcloud_major_version: capabilities_response_major_version)

          mock_server_config_check_response(storage_host,
                                            response_code: check_config_response_code,
                                            response_headers: check_config_response_headers,
                                            response_body: check_config_response_body)
        end

        context 'when connection fails' do
          before do
            allow(Net::HTTP).to receive(:start).and_raise(SocketError, 'Failed to open TCP connection (SIMULATED)')
          end

          include_examples 'contract is invalid', host: :cannot_be_connected_to
        end

        context 'when response code is a 404 NOT FOUND' do
          let(:capabilities_response_code) { 404 }

          include_examples 'contract is invalid', host: :cannot_be_connected_to
        end

        context 'when response code is a 500 PERMISSION DENIED' do
          let(:capabilities_response_code) { 500 }

          include_examples 'contract is invalid', host: :cannot_be_connected_to
        end

        context 'when response content type is not application/json' do
          let(:capabilities_response_headers) do
            {
              'Content-Type' => 'text/html'
            }
          end

          include_examples 'contract is invalid', host: :not_nextcloud_server
        end

        context 'when response is unparsable JSON' do
          let(:capabilities_response_body) { '{' }

          include_examples 'contract is invalid', host: :not_nextcloud_server
        end

        context 'when response is valid JSON but not the expected data' do
          let(:capabilities_response_body) { '{}' }

          include_examples 'contract is invalid', host: :not_nextcloud_server
        end

        context 'when Nextcloud version is below the required minimal version which is 22' do
          let(:capabilities_response_major_version) { 21 }

          include_examples 'contract is invalid', host: :minimal_nextcloud_version_unmet
        end

        context 'when Nextcloud instance is missing the "OpenProject integration" app' do
          let(:check_config_response_code) { 302 }

          include_examples 'contract is invalid', host: :op_application_not_installed
        end

        context 'when Nextcloud instance is misconfigured and strips AUTHORIZATION header from HTTP request' do
          let(:check_config_response_body) { { authorization_header: '' }.to_json }

          include_examples 'contract is invalid', host: :authorization_header_missing
        end
      end
    end

    context 'when host secure' do
      context 'when host is localhost' do
        let(:storage_host) { 'http://localhost:1234' }

        include_examples 'contract is valid'
      end

      context 'when host uses https protocol' do
        let(:storage_host) { 'https://172.16.193.146' }

        include_examples 'contract is valid'
      end
    end
  end
end
