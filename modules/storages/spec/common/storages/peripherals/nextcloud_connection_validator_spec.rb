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
    Storages::Peripherals::Registry.stub("#{storage.short_provider_type}.queries.capabilities", ->(_) { response })
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

  context "if nextcloud host url could not be found" do
    let(:storage) { create(:nextcloud_storage_configured) }
    let(:response) { build_failure(code: :not_found, payload: nil) }

    it "returns a validation failure" do
      expect(subject.type).to eq(:error)
      expect(subject.error_code).to eq(:err_host_not_found)
      expect(subject.description)
        .to eq("No Nextcloud server found at the configured host url. Please check the configuration.")
    end
  end

  context "if request returns a capabilities response" do
    let(:storage) { create(:nextcloud_storage_configured, :as_automatically_managed) }
    let(:app_enabled) { true }
    let(:app_version) { Storages::SemanticVersion.parse("2.6.3") }
    let(:group_folder_enabled) { true }
    let(:group_folder_version) { Storages::SemanticVersion.parse("17.0.1") }
    let(:response) do
      ServiceResult.success(result: Storages::NextcloudCapabilities.new(
        app_enabled?: app_enabled,
        app_version:,
        group_folder_enabled?: group_folder_enabled,
        group_folder_version:
      ))
    end

    it "returns a healthy validation" do
      expect(subject.type).to eq(:healthy)
      expect(subject.error_code).to eq(:none)
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

      context "with disabled/not installed group folder app" do
        let(:group_folder_enabled) { false }

        it "returns a validation failure" do
          expect(subject.type).to eq(:error)
          expect(subject.error_code).to eq(:err_missing_dependencies)
          expect(subject.description).to eq("A required dependency is missing on the file storage. " \
                                            "Please add the following dependency: Group folders.")
        end

        context "if storage is not automatically_managed" do
          let(:storage) { create(:nextcloud_storage_configured) }

          it "does not check group_folder app" do
            expect(subject.type).to eq(:healthy)
            expect(subject.error_code).to eq(:none)
          end
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

        context "if storage is not automatically_managed" do
          let(:storage) { create(:nextcloud_storage_configured) }

          it "does not check group_folder app" do
            expect(subject.type).to eq(:healthy)
            expect(subject.error_code).to eq(:none)
          end
        end
      end
    end
  end

  context "if query returns an unhandled error" do
    let(:storage) { create(:nextcloud_storage_configured) }
    let(:response) { build_failure(code: :error, payload: nil) }

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

  private

  def build_failure(code:, payload:)
    data = Storages::StorageErrorData.new(source: "query", payload:)
    error = Storages::StorageError.new(code:, data:)
    ServiceResult.failure(result: code, errors: error)
  end
end
