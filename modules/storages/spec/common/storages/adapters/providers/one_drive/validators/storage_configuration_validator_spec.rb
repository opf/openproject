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

module Storages
  module Adapters
    module Providers
      module OneDrive
        module Validators
          RSpec.describe StorageConfigurationValidator, :disable_ssrf_filter, :webmock do
            let(:storage) { create(:one_drive_sandbox_storage, :as_automatically_managed) }
            let(:auth_strategy) { Registry["one_drive.authentication.userless"].call }
            let(:error) { Results::Error.new(code: error_code, source: self) }

            subject(:validator) { described_class.new(storage) }

            it "returns a ResultGroup", vcr: "one_drive/files_query_userless" do
              results = validator.call

              expect(results).to be_a(HealthReport::ResultGroup)
              expect(results).to be_success
            end

            describe "possible error scenarios" do
              let(:files_double) { class_double(Queries::FilesQuery) }
              let(:input_data) { Input::Files.build(folder: "/").value! }
              let(:result) { Success() }

              before do
                allow(files_double).to receive(:call).with(storage:, auth_strategy:, input_data:).and_return(result)
              end

              context "when the storage isn't configured" do
                let(:storage) { create(:one_drive_storage) }

                it "the check fails" do
                  results = validator.call
                  expect(results[:storage_configured]).to be_a_failure
                  expect(results[:storage_configured].code).to eq(:not_configured)
                end
              end

              context "when diagnostic request fails with an unhandled error" do
                let(:error_code) { :error }
                let(:result) { Failure(error) }

                before { Registry.stub("one_drive.queries.files", files_double) }

                it "the check fails" do
                  results = validator.call

                  expect(results[:diagnostic_request]).to be_a_failure
                  expect(results[:diagnostic_request].code).to eq(:unknown_error)
                end

                it "logs an error" do
                  allow(Rails.logger).to receive(:error)
                  validator.call

                  expect(Rails.logger).to have_received(:error).with(/Connection validation failed with unknown/)
                end
              end

              context "when the tenant id is wrong" do
                it "but looks like an actual valid value", vcr: "one_drive/validation_wrong_tenant_id" do
                  storage.tenant_id = "itdoesnotexists9000.sharepoint.com"
                  results = described_class.new(storage).call

                  expect(results[:tenant_id]).to be_a_failure
                  expect(results[:tenant_id].code).to eq(:od_tenant_id_invalid)
                end

                it "but is blatantly wrong", vcr: "one_drive/validation_absurd_tenant_id" do
                  storage.tenant_id = "wrong"
                  results = described_class.new(storage).call

                  expect(results[:tenant_id]).to be_a_failure
                  expect(results[:tenant_id].code).to eq(:od_tenant_id_invalid)
                end
              end

              context "when the client secret is wrong" do
                it "fails the check", vcr: "one_drive/validation_wrong_client_secret" do
                  storage.oauth_client.client_secret = "wrong"
                  results = described_class.new(storage).call

                  expect(results[:client_secret]).to be_a_failure
                  expect(results[:client_secret].code).to eq(:client_secret_invalid)
                end
              end

              context "when the client id is wrong" do
                it "fails the check", vcr: "one_drive/validation_wrong_client_id" do
                  storage.oauth_client.client_id = "wrong"
                  results = described_class.new(storage).call

                  expect(results[:client_id]).to be_a_failure
                  expect(results[:client_id].code).to eq(:client_id_invalid)
                end
              end

              context "when the drive id is wrong" do
                it "fails when looks malformed", vcr: "one_drive/validation_drive_id_malformed" do
                  storage.drive_id = "not-a-drive-id"
                  results = described_class.new(storage).call

                  expect(results[:drive_id_format]).to be_a_failure
                  expect(results[:drive_id_format].code).to eq(:od_drive_id_invalid)
                end

                it "fails when is not found", vcr: "one_drive/validation_drive_id_not_found" do
                  storage.drive_id = "#{storage.drive_id[0..-2]}0"
                  results = described_class.new(storage).call

                  expect(results[:drive_id_exists]).to be_a_failure
                  expect(results[:drive_id_exists].code).to eq(:od_drive_id_not_found)
                end
              end
            end
          end
        end
      end
    end
  end
end
