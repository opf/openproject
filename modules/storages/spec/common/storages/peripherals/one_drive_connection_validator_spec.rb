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

RSpec.describe Storages::Peripherals::OneDriveConnectionValidator do
  let(:storage) { create(:one_drive_storage, oauth_client: create(:oauth_client)) }

  before do
    Storages::Peripherals::Registry.stub("#{storage.short_provider_type}.queries.files", ->(_) { response })
  end

  subject { described_class.new(storage:).validate }

  context "if storage is not yet configured" do
    let(:storage) { create(:one_drive_storage) }

    it "returns a validation failure" do
      expect(subject.type).to eq(:none)
      expect(subject.error_code).to eq(:wrn_not_configured)
      expect(subject.description).to eq("The connection could not be validated. Please finish configuration first.")
    end
  end

  context "if the storage's tenant id could not be found" do
    let(:error_payload) do
      {
        error: "invalid_request",
        error_description: "There is an error. Tenant '#{storage.tenant_id}' not found. This is VERY bad."
      }.to_json
    end
    let(:response) { build_failure(code: :unauthorized, payload: error_payload) }

    it "returns a validation failure" do
      expect(subject.type).to eq(:error)
      expect(subject.error_code).to eq(:err_tenant_invalid)
      expect(subject.description)
        .to eq("The configured directory (tenant) id is invalid. Please check the configuration.")
    end
  end

  context "if the storage's client id could not be found" do
    let(:error_payload) { { error: "unauthorized_client" }.to_json }
    let(:response) { build_failure(code: :unauthorized, payload: error_payload) }

    it "returns a validation failure" do
      expect(subject.type).to eq(:error)
      expect(subject.error_code).to eq(:err_client_invalid)
      expect(subject.description).to eq("The configured OAuth 2 client id is invalid. Please check the configuration.")
    end
  end

  context "if the storage's client secret is wrong" do
    let(:error_payload) { { error: "invalid_client" }.to_json }
    let(:response) { build_failure(code: :unauthorized, payload: error_payload) }

    it "returns a validation failure" do
      expect(subject.type).to eq(:error)
      expect(subject.error_code).to eq(:err_client_invalid)
      expect(subject.description)
        .to eq("The configured OAuth 2 client secret is invalid. Please check the configuration.")
    end
  end

  context "if the storage's drive id could not be found" do
    let(:response) { build_failure(code: :not_found, payload: nil) }

    it "returns a validation failure" do
      expect(subject.type).to eq(:error)
      expect(subject.error_code).to eq(:err_drive_invalid)
      expect(subject.description).to eq("The configured drive id could not be found. Please check the configuration.")
    end
  end

  context "if the storage's drive id is malformed" do
    let(:error_payload) do
      {
        error: {
          code: "invalidRequest",
          message: "The provided drive id appears to be malformed, or does not represent a valid drive."
        }
      }
    end
    let(:response) { build_failure(code: :error, payload: error_payload) }

    it "returns a validation failure" do
      expect(subject.type).to eq(:error)
      expect(subject.error_code).to eq(:err_drive_invalid)
      expect(subject.description).to eq("The configured drive id could not be found. Please check the configuration.")
    end
  end

  context "if the request fails with an unknown error" do
    let(:response) { build_failure(code: :error, payload: nil) }

    before do
      allow(Rails.logger).to receive(:error)
    end

    it "returns a validation failure" do
      expect(subject.type).to eq(:error)
      expect(subject.error_code).to eq(:err_unknown)
      expect(subject.description)
        .to eq("The connection could not be validated. An unknown error occurred. " \
               "Please check the server logs for further information.")
    end

    it "logs the error message" do
      described_class.new(storage:).validate
      expect(Rails.logger).to have_received(:error)
    end
  end

  context "if the request returns unexpected files" do
    let(:storage) { create(:one_drive_storage, :as_automatically_managed, oauth_client: create(:oauth_client)) }
    let(:project_folder_id) { "1337" }
    let(:project_storage) do
      create(:project_storage,
             :as_automatically_managed,
             project_folder_id:,
             storage:,
             project: create(:project))
    end
    let(:files_result) do
      Storages::StorageFiles.new(
        [
          Storages::StorageFile.new(id: project_folder_id, name: "I am your father"),
          Storages::StorageFile.new(id: "noooooooooo", name: "testimony_of_luke_skywalker.md")
        ],
        Storages::StorageFile.new(id: "root", name: "root"),
        []
      )
    end
    let(:response) { ServiceResult.success(result: files_result) }

    before do
      project_storage
    end

    it "returns a validation failure" do
      expect(subject.type).to eq(:warning)
      expect(subject.error_code).to eq(:wrn_unexpected_content)
      expect(subject.description).to eq("Unexpected content found in the drive.")
    end
  end

  context "if everything was fine" do
    let(:response) { ServiceResult.success }

    it "returns a validation success" do
      expect(subject.type).to eq(:healthy)
      expect(subject.error_code).to eq(:none)
      expect(subject.description).to be_nil
    end
  end

  private

  def build_failure(code:, payload:)
    data = Storages::StorageErrorData.new(source: "query", payload:)
    error = Storages::StorageError.new(code:, data:)
    ServiceResult.failure(result: code, errors: error)
  end
end
