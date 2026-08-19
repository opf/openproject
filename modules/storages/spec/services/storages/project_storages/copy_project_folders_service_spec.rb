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

RSpec.describe Storages::ProjectStorages::CopyProjectFoldersService, :webmock do
  # using Storages::Peripherals::ServiceResultRefinements

  let(:storage) { create(:nextcloud_storage, :as_automatically_managed) }
  let(:target) { create(:project_storage, storage:) }
  let(:system_user) { create(:system) }
  let(:result_data) { Storages::Adapters::Results::CopyTemplateFolder.new(nil, nil, false) }
  let(:copy_folder_command) { class_double(Storages::Adapters::Providers::Nextcloud::Commands::CopyTemplateFolderCommand) }
  let(:input_data) do
    Storages::Adapters::Input::CopyTemplateFolder
      .build(source: source.managed_project_folder_path, destination: target.managed_project_folder_path).value!
  end
  let(:auth_strategy) { Storages::Adapters::Registry["nextcloud.authentication.userless"].call }

  subject(:service) { described_class }

  before { Storages::Adapters::Registry.stub("nextcloud.commands.copy_template_folder", copy_folder_command) }

  context "with automatically managed project folders" do
    let(:source) { create(:project_storage, :as_automatically_managed, storage:) }

    before do
      allow(copy_folder_command).to receive(:call)
                                      .with(storage:, auth_strategy:, input_data:)
                                      .and_return(Success(result_data.with(polling_url: "https://polling.url.de/cool/subresources")))
    end

    it "if polling is required, returns a nil id and an url" do
      result = service.call(source:, target:)

      expect(result).to be_success
      expect(result.result.to_h).to eq({ id: nil, polling_url: "https://polling.url.de/cool/subresources",
                                         requires_polling: false })
    end
  end

  context "with manually managed project folders" do
    let(:source) { create(:project_storage, project_folder_id: "this_is_a_unique_id", project_folder_mode: "manual") }

    it "succeeds" do
      result = service.call(source:, target:)
      expect(result).to be_success
    end

    it "returns the source folder id" do
      result = service.call(source:, target:)

      expect(result.result.id).to eq(source.project_folder_id)
    end
  end

  context "with non-managed project folders" do
    let(:source) { create(:project_storage, project_folder_id: nil, project_folder_mode: "inactive") }

    it "logs the occurrence" do
      allow(Rails.logger).to receive(:info)
      service.call(source:, target:)
      expect(Rails.logger)
        .to have_received(:info).with("#{source.storage.name} on #{source.project.name} is inactive. Skipping copy.")
    end

    it "succeeds" do
      expect(service.call(source:, target:)).to be_success
    end

    it "returns the origin folder id (nil)" do
      result = service.call(source:, target:)

      expect(result.result.id).to eq(source.project_folder_id)
    end
  end

  describe "error messages" do
    let(:source) { create(:project_storage, :as_automatically_managed, storage:) }

    it "the target folder already exists" do
      allow(copy_folder_command).to receive(:call).with(storage:, auth_strategy:, input_data:)
                                                  .and_return(build_failure(:conflict))
      result = service.call(source:, target:)

      expect(result).to be_failure
      expect(result.errors[:base])
        .to contain_exactly(I18n.t("services.errors.models.copy_project_folders_service.conflict",
                                   destination_path: target.managed_project_folder_path))
    end

    it "source folder was not found" do
      allow(copy_folder_command).to receive(:call).with(storage:, auth_strategy:, input_data:)
                                                  .and_return(build_failure(:not_found))

      result = service.call(source:, target:)

      expect(result).to be_failure
      expect(result.errors[:base])
        .to contain_exactly(I18n.t("services.errors.models.copy_project_folders_service.not_found",
                                   source_path: source.project_folder_location))
    end

    it "token is unauthorized to do the copy" do
      allow(copy_folder_command).to receive(:call).with(storage:, auth_strategy:, input_data:)
                                                  .and_return(build_failure(:unauthorized))
      result = service.call(source:, target:)

      expect(result).to be_failure
      expect(result.errors[:base])
        .to contain_exactly(I18n.t("services.errors.models.copy_project_folders_service.unauthorized"))
    end

    it "token has no access to the source folder" do
      allow(copy_folder_command).to receive(:call).with(storage:, auth_strategy:, input_data:)
                                                  .and_return(build_failure(:forbidden))
      result = service.call(source:, target:)

      expect(result).to be_failure
      expect(result.errors[:base])
        .to contain_exactly(I18n.t("services.errors.models.copy_project_folders_service.forbidden",
                                   source_path: source.project_folder_location))
    end
  end

  private

  def build_failure(code)
    error = Storages::Adapters::Results::Error.new(source: copy_folder_command).with(code:)
    Failure(error)
  end
end
