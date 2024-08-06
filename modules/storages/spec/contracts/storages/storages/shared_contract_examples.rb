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

require "spec_helper"
require_module_spec_helper
require "contracts/shared/model_contract_shared_context"

RSpec.shared_examples_for "storage contract" do
  describe "validations" do
    context "when all attributes are valid" do
      include_examples "contract is valid"
    end

    context "when name is invalid" do
      context "as it is too long" do
        let(:storage_name) { "X" * 257 }

        include_examples "contract is invalid", name: :too_long
      end

      context "as it is empty" do
        let(:storage_name) { "" }

        include_examples "contract is invalid", name: :blank
      end

      context "as it is nil" do
        let(:storage_name) { nil }

        include_examples "contract is invalid", name: :blank
      end
    end

    context "when provider_type is invalid" do
      context "as it is empty" do
        let(:storage_provider_type) { "" }

        include_examples "contract is invalid", provider_type: :inclusion
      end

      context "as it is nil" do
        let(:storage_provider_type) { nil }

        include_examples "contract is invalid", provider_type: :inclusion
      end
    end
  end

  include_examples "contract reuses the model errors"
end

RSpec.shared_examples_for "onedrive storage contract" do
  include_context "ModelContract shared context"

  let(:current_user) { create(:admin) }
  let(:storage_name) { "Storage 1" }
  let(:storage_provider_type) { Storages::Storage::PROVIDER_TYPE_ONE_DRIVE }
  let(:storage_creator) { current_user }

  it_behaves_like "contract is valid for active admins and invalid for regular users"

  it_behaves_like "storage contract"
end

RSpec.shared_examples_for "nextcloud storage contract", :storage_server_helpers, :webmock do
  include_context "ModelContract shared context"

  # Only admins have the right to create/delete storages.
  let(:current_user) { create(:admin) }
  let(:storage_name) { "Storage 1" }
  let(:storage_provider_type) { Storages::Storage::PROVIDER_TYPE_NEXTCLOUD }
  let(:storage_host) { "https://host1.example.com" }
  let(:storage_creator) { current_user }

  before do
    if storage_host.present?
      mock_server_capabilities_response(storage_host)
      mock_server_config_check_response(storage_host)
      mock_nextcloud_application_credentials_validation(storage_host)
    end
  end

  it_behaves_like "contract is valid for active admins and invalid for regular users"

  it_behaves_like "storage contract"

  describe "validations" do
    context "when host is invalid" do
      context "as host is not a URL" do
        let(:storage_host) { "---invalid-url---" }

        include_examples "contract is invalid", host: :invalid_host_url
      end

      context "as host is an empty string" do
        let(:storage_host) { "" }

        include_examples "contract is invalid", host: :invalid_host_url
      end

      context "as host is longer than 255" do
        let(:storage_host) { "http://#{'a' * 250}.com" }

        include_examples "contract is invalid", host: :too_long
      end

      context "as host is nil" do
        let(:storage_host) { nil }

        include_examples "contract is invalid", host: :url
      end

      context "when host is an unsafe IP" do
        let(:storage_host) { "http://172.16.193.146" }

        include_examples "contract is invalid", host: :url_not_secure_context
      end

      context "when host is an unsafe hostname" do
        let(:storage_host) { "http://nc.openproject.com" }

        include_examples "contract is invalid", host: :url_not_secure_context
      end

      context "when provider_type is nextcloud" do
        let(:capabilities_response_body) { nil } # use default
        let(:capabilities_response_code) { nil } # use default
        let(:capabilities_response_headers) { nil } # use default
        let(:capabilities_response_major_version) { 22 }
        let(:check_config_response_body) { nil } # use default
        let(:check_config_response_code) { nil } # use default
        let(:check_config_response_headers) { nil } # use default
        let(:timeout_server_capabilities) { false }
        let(:timeout_server_config_check) { false }
        let(:stub_server_capabilities) do
          mock_server_capabilities_response(storage_host,
                                            response_code: capabilities_response_code,
                                            response_headers: capabilities_response_headers,
                                            response_body: capabilities_response_body,
                                            timeout: timeout_server_capabilities,
                                            response_nextcloud_major_version: capabilities_response_major_version)
        end
        let(:stub_config_check) do
          mock_server_config_check_response(storage_host,
                                            response_code: check_config_response_code,
                                            response_headers: check_config_response_headers,
                                            timeout: timeout_server_config_check,
                                            response_body: check_config_response_body)
        end

        before do
          # simulate host value changed to have GET request sent to check host URL validity
          storage.host_will_change!

          # simulate http response returned upon GET request
          stub_server_capabilities
          stub_config_check
        end

        context "when connection fails" do
          context "when server capabilities request times out" do
            let(:timeout_server_capabilities) { true }

            include_examples "contract is invalid", host: :cannot_be_connected_to

            it "retries failed request once" do
              contract.validate
              # twice due to HTTPX retry plugin being enabled.
              expect(stub_server_capabilities).to have_been_made.twice
            end
          end

          context "when server config check request times out" do
            let(:timeout_server_config_check) { true }

            include_examples "contract is invalid", host: :cannot_be_connected_to

            it "retries failed request once" do
              contract.validate
              # twice due to HTTPX retry plugin being enabled.
              expect(stub_config_check).to have_been_made.twice
            end
          end
        end

        context "when response code is a 404 NOT FOUND" do
          let(:capabilities_response_code) { 404 }

          include_examples "contract is invalid", host: :cannot_be_connected_to
        end

        context "when response code is a 500 PERMISSION DENIED" do
          let(:capabilities_response_code) { 500 }

          include_examples "contract is invalid", host: :cannot_be_connected_to
        end

        context "when response content type is not application/json" do
          let(:capabilities_response_headers) do
            {
              "Content-Type" => "text/html"
            }
          end

          include_examples "contract is invalid", host: :not_nextcloud_server
        end

        context "when response is unparsable JSON" do
          let(:capabilities_response_body) { "{" }

          include_examples "contract is invalid", host: :not_nextcloud_server
        end

        context "when response is valid JSON but not the expected data" do
          let(:capabilities_response_body) { "{}" }

          include_examples "contract is invalid", host: :not_nextcloud_server
        end

        context "when Nextcloud version is below the required minimal version which is 22" do
          let(:capabilities_response_major_version) { 21 }

          include_examples "contract is invalid", host: :minimal_nextcloud_version_unmet
        end

        context 'when Nextcloud instance is missing the "OpenProject integration" app' do
          let(:check_config_response_code) { 302 }

          include_examples "contract is invalid", host: :op_application_not_installed
        end

        context "when Nextcloud instance is misconfigured and strips AUTHORIZATION header from HTTP request" do
          let(:check_config_response_body) { { authorization_header: "" }.to_json }

          include_examples "contract is invalid", host: :authorization_header_missing
        end
      end
    end

    context "when host secure" do
      context "when host is localhost" do
        let(:storage_host) { "http://localhost:1234" }

        include_examples "contract is valid"
      end

      context "when host uses https protocol" do
        let(:storage_host) { "https://172.16.193.146" }

        include_examples "contract is valid"
      end
    end

    context "when automatically managed, no username or password" do
      before { storage.automatic_management_enabled = true }

      it_behaves_like "contract is invalid", password: :blank
    end

    context "when automatically managed, with username and password" do
      before do
        storage.assign_attributes(automatic_management_enabled: true, username: "OpenProject", password: "Password")
      end

      it_behaves_like "contract is valid"
    end

    context "when not automatically managed, no username or password" do
      before do
        storage.provider_fields = {}
        storage.assign_attributes(automatic_management_enabled: false)
      end

      it_behaves_like "contract is valid"
    end

    context "when not automatically managed, with username default and password" do
      before do
        storage.assign_attributes(automatic_management_enabled: false, username: "OpenProject", password: "Password")
      end

      it_behaves_like "contract is invalid", password: :present
    end

    context "when not automatically managed, with user defined username and password" do
      before do
        storage.assign_attributes(automatic_management_enabled: false, username: "Username", password: "Password")
      end

      it_behaves_like "contract is invalid", username: :present, password: :present
    end

    describe "provider_type_strategy" do
      before do
        allow(contract).to receive(:provider_type_strategy)
      end

      context "without `skip_provider_type_strategy` option" do
        it "validates the provider type contract" do
          contract.validate

          expect(contract).to have_received(:provider_type_strategy)
        end
      end

      context "with `skip_provider_type_strategy` option" do
        let(:contract) do
          described_class.new(storage, build_stubbed(:admin),
                              options: { skip_provider_type_strategy: true })
        end

        it "does not validate the provider type" do
          contract.validate

          expect(contract).not_to have_received(:provider_type_strategy)
        end
      end
    end
  end
end
