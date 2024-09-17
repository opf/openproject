#-- copyright
#++

require "spec_helper"
require_module_spec_helper

RSpec.describe Storages::FileLinks::CopyFileLinksService, :webmock do
  let(:source) { create(:nextcloud_storage_with_complete_configuration) }
  let(:target) { create(:nextcloud_storage_with_complete_configuration) }

  let(:source_storage) { create(:project_storage, storage: source, project_folder_mode: "automatic") }
  let(:target_storage) { create(:project_storage, storage: target, project_folder_mode: "automatic") }

  let(:source_wp) { create_list(:work_package, 5, project: source_storage.project) }
  let(:target_wp) { create_list(:work_package, 5, project: target_storage.project) }

  let(:source_links) { source_wp.map { create(:file_link, container: _1, storage: source) } }

  let(:wp_map) { source_wp.map(&:id).zip(target_wp.map(&:id)).to_h }

  let(:user) { create(:user) }

  subject(:service) { described_class.new(source: source_storage, target: target_storage, user:, work_packages_map: wp_map) }

  before { source_links }

  context "when unmanaged storage" do
    let(:source_storage) { create(:project_storage, storage: source, project_folder_mode: "manual") }
    let(:target_storage) { create(:project_storage, storage: target, project_folder_mode: "manual") }

    it "creates file links pointing to the same files" do
      expect { service.call }.to change(Storages::FileLink, :count).by(5)

      Storages::FileLink.last(5).each_with_index do |link, index|
        expect(link.origin_id).to eq(source_links[index].origin_id)
      end
    end
  end

  context "when AMPF is enabled" do
    let(:files_info) { class_double(Storages::Peripherals::StorageInteraction::Nextcloud::FilesInfoQuery) }
    let(:file_path_to_id) { class_double(Storages::Peripherals::StorageInteraction::Nextcloud::FilePathToIdMapQuery) }
    let(:auth_strategy) do
      Storages::Peripherals::StorageInteraction::AuthenticationStrategies::Strategy.new(key: :basic_auth)
    end

    let(:target_folder) { Storages::Peripherals::ParentFolder.new(target_storage.managed_project_folder_path) }

    let(:remote_source_info) do
      source_links.map do |link|
        Storages::StorageFileInfo.new(status: "ok", status_code: 200, id: link.origin_id, name: link.origin_name,
                                      location: File.join(source_storage.managed_project_folder_path, link.origin_name))
      end
    end

    let(:path_to_ids) do
      source_links.each_with_object({}) do |link, hash|
        key = File.join(target_storage.managed_project_folder_path, link.origin_name)
        id = Storages::StorageFileId.new(id: "#{link.origin_id}_target")
        hash[key] = id
      end
    end

    before do
      Storages::Peripherals::Registry.stub("nextcloud.queries.files_info", files_info)
      Storages::Peripherals::Registry.stub("nextcloud.authentication.userless", -> { auth_strategy })
      Storages::Peripherals::Registry.stub("nextcloud.queries.file_path_to_id_map", file_path_to_id)

      allow(Storages::Peripherals::ParentFolder).to receive(:new).with(target_storage.project_folder_location)
                                                                 .and_return(target_folder)

      allow(files_info).to receive(:call).with(file_ids: source_links.map(&:origin_id), storage: source, auth_strategy:)
                                         .and_return(ServiceResult.success(result: remote_source_info))

      allow(file_path_to_id).to receive(:call).with(storage: target, auth_strategy:, folder: target_folder)
                                              .and_return(ServiceResult.success(result: path_to_ids))
    end

    it "create links to the newly copied files" do
      expect { service.call }.to change(Storages::FileLink, :count).by(5)

      Storages::FileLink.last(5).each do |link|
        expect(link.origin_id).to match /_target$/
        expect(link.storage_id).to eq(target.id)
      end
    end
  end
end
