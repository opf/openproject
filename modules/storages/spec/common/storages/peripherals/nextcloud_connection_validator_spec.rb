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

RSpec.describe Storages::Peripherals::NextcloudConnectionValidator do
  before do
    Storages::Peripherals::Registry.stub("#{storage}.queries.capabilities", ->(_) { capabilities_response })
    Storages::Peripherals::Registry.stub("#{storage}.queries.files", ->(_) { files_response })
  end

  subject { described_class.new(storage:).validate }

  context "if storage is not yet configured" do
    let(:storage) { create(:nextcloud_storage) }

    it "returns a validation failure" do
      expect(subject.type).to eq(:none)
      expect(subject.error_code).to eq(:wrn_not_configured)
      expect(subject.description).to eq("The connection could not be validated. Please finish configuration first.")
    end
  end

  context "if storage is not configured for automatic folder management" do
    let(:storage) { create(:nextcloud_storage_configured, :as_not_automatically_managed) }
    let(:app_enabled) { true }
    let(:app_version) { Storages::SemanticVersion.parse("2.6.3") }
    let(:capabilities_response) do
      ServiceResult.success(result: Storages::NextcloudCapabilities.new(
        app_enabled?: app_enabled,
        app_version:,
        group_folder_enabled?: false,
        group_folder_version: nil
      ))
    end

    it "returns a healthy validation" do
      expect(subject.type).to eq(:healthy)
      expect(subject.error_code).to eq(:none)
    end

    context "if nextcloud host url could not be found" do
      let(:capabilities_response) { build_failure(code: :not_found, payload: nil) }

      it "returns a validation failure" do
        expect(subject.type).to eq(:error)
        expect(subject.error_code).to eq(:err_host_not_found)
        expect(subject.description)
          .to eq("No Nextcloud server found at the configured host url. Please check the configuration.")
      end
    end

    context "if nextcloud server instance is badly configured" do
      context "with missing integration app" do
        let(:app_enabled) { false }

        it "returns a validation failure" do
          expect(subject.type).to eq(:error)
          expect(subject.error_code).to eq(:err_missing_dependencies)
          expect(subject.description).to eq("A required dependency is missing on the file storage. " \
                                            "Please add the following dependency: Integration OpenProject.")
        end
      end

      context "with outdated integration app" do
        let(:app_version) { Storages::SemanticVersion.parse("2.4.3") }

        it "returns a validation failure" do
          expect(subject.type).to eq(:error)
          expect(subject.error_code).to eq(:err_unexpected_version)
          expect(subject.description)
            .to eq("The Integration OpenProject app version is not supported. Please update your Nextcloud server.")
        end
      end

      context "if capabilities query returns an unhandled error" do
        let(:capabilities_response) { build_failure(code: :error, payload: nil) }

        before do
          allow(Rails.logger).to receive(:error)
        end

        it "returns a validation failure" do
          expect(subject.type).to eq(:error)
          expect(subject.error_code).to eq(:err_unknown)
          expect(subject.description).to eq("The connection could not be validated. An unknown error occurred. " \
                                            "Please check the server logs for further information.")
        end

        it "logs the error message" do
          described_class.new(storage:).validate
          expect(Rails.logger).to have_received(:error).with(/Connection validation failed with unknown error/)
        end
      end
    end
  end

  context "if storage is configured for automatic folder management" do
    let(:storage) { create(:nextcloud_storage_configured, :as_automatically_managed) }
    let(:group_folder_enabled) { true }
    let(:group_folder_version) { Storages::SemanticVersion.parse("17.0.1") }
    let(:capabilities_response) do
      ServiceResult.success(result: Storages::NextcloudCapabilities.new(
        app_enabled?: true,
        app_version: Storages::SemanticVersion.parse("2.6.3"),
        group_folder_enabled?: group_folder_enabled,
        group_folder_version:
      ))
    end
    let(:project_folder_id) { "1337" }
    let(:project_storage) do
      create(:project_storage,
             :as_automatically_managed,
             project_folder_id:,
             storage:,
             project: create(:project))
    end

    before { project_storage }

    context "with disabled/not installed group folder app" do
      let(:group_folder_enabled) { false }

      it "returns a validation failure" do
        expect(subject.type).to eq(:error)
        expect(subject.error_code).to eq(:err_missing_dependencies)
        expect(subject.description).to eq("A required dependency is missing on the file storage. " \
                                          "Please add the following dependency: Group folders.")
      end
    end

    context "with outdated group folder app" do
      let(:group_folder_version) { Storages::SemanticVersion.parse("11.0.1") }

      it "returns a validation failure" do
        expect(subject.type).to eq(:error)
        expect(subject.error_code).to eq(:err_unexpected_version)
        expect(subject.description)
          .to eq("The Group Folder version is not supported. Please update your Nextcloud server.")
      end
    end

    context "if userless authentication fails" do
      let(:files_response) { build_failure(code: :unauthorized, payload: nil) }

      it "returns a validation failure" do
        expect(subject.type).to eq(:error)
        expect(subject.error_code).to eq(:err_userless_access_denied)
        expect(subject.description).to eq("The configured app password is invalid.")
      end
    end

    context "if the files request returns not_found" do
      let(:files_response) { build_failure(code: :not_found, payload: nil) }

      it "returns a validation failure" do
        expect(subject.type).to eq(:error)
        expect(subject.error_code).to eq(:err_group_folder_not_found)
        expect(subject.description).to eq("The group folder could not be found.")
      end
    end

    context "if the files request returns an unknown error" do
      let(:files_response) do
        Storages::Peripherals::StorageInteraction::Nextcloud::Util.error(:error)
      end

      before do
        allow(Rails.logger).to receive(:error)
      end

      it "returns a validation failure" do
        expect(subject.type).to eq(:error)
        expect(subject.error_code).to eq(:err_unknown)
        expect(subject.description).to eq("The connection could not be validated. An unknown error occurred. " \
                                          "Please check the server logs for further information.")
      end

      it "logs the error message" do
        described_class.new(storage:).validate
        expect(Rails.logger).to have_received(:error).with(/Connection validation failed with unknown error/)
      end
    end

    context "if the files request returns unexpected files" do
      let(:files_response) do
        ServiceResult.success(result: Storages::StorageFiles.new(
          [
            Storages::StorageFile.new(id: project_folder_id, name: "I am your father"),
            Storages::StorageFile.new(id: "noooooooooo", name: "testimony_of_luke_skywalker.md")
          ],
          Storages::StorageFile.new(id: "root", name: "root"),
          []
        ))
      end

      it "returns a validation failure" do
        expect(subject.type).to eq(:warning)
        expect(subject.error_code).to eq(:wrn_unexpected_content)
        expect(subject.description).to eq("Unexpected content found in the managed group folder.")
      end
    end
  end

  private

  def build_failure(code:, payload:)
    data = Storages::StorageErrorData.new(source: "query", payload:)
    error = Storages::StorageError.new(code:, data:)
    ServiceResult.failure(result: code, errors: error)
  end
end
