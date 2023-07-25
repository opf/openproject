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
require 'webmock/rspec'

RSpec.describe Storages::FileLinkSyncService, type: :model do
  let(:user) { create(:user) }
  let(:role) { create(:existing_role, permissions: [:manage_file_links]) }
  let(:project) { create(:project, members: { user => role }) }
  let(:work_package) { create(:work_package, project:) }

  let(:storage_one) { create(:storage, host: "https://host-1.example.org") }
  let(:storage_two) { create(:storage, host: "https://host-2.example.org") }

  let(:file_link_one) { create(:file_link, storage: storage_one, container: work_package) }
  let(:file_link_two) { create(:file_link, storage: storage_two, container: work_package) }

  let(:file_links) { [file_link_one] }

  let(:files_info_query) { instance_double(Storages::Peripherals::StorageInteraction::Nextcloud::FilesInfoQuery) }

  subject { described_class.new(user:).call(file_links) }

  before do
    storage_requests = instance_double(Storages::Peripherals::StorageRequests)
    allow(storage_requests).to receive(:files_info_query).and_return(files_info_query)
    allow(Storages::Peripherals::StorageRequests).to receive(:new).and_return(storage_requests)
  end

  describe '#call' do
    context 'with one file link' do
      let(:file_info) { build(:storage_file_info) }
      let(:file_link_one) { create(:file_link, origin_id: file_info.id, storage: storage_one, container: work_package) }

      before do
        allow(files_info_query).to receive(:call).and_return(ServiceResult.success(result: [file_info]))
      end

      it 'updates all origin_* fields' do
        expect(subject.success).to be_truthy
        expect(subject.result.count).to be 1
        expect(subject.result.first).to be_a Storages::FileLink

        expect(subject.result.first.origin_id).to eql file_info.id
        expect(subject.result.first.origin_created_at).to eql file_info.created_at
        expect(subject.result.first.origin_updated_at).to eql file_info.last_modified_at
        expect(subject.result.first.origin_mime_type).to eql file_info.mime_type
        expect(subject.result.first.origin_name).to eql file_info.name
        expect(subject.result.first.origin_created_by_name).to eql file_info.owner_name
      end
    end

    context 'without permission to read file (403)' do
      let(:file_info) { build(:storage_file_info, status_code: 403) }
      let(:file_link_one) { create(:file_link, origin_id: file_info.id, storage: storage_one, container: work_package) }

      before do
        allow(files_info_query).to receive(:call).and_return(ServiceResult.success(result: [file_info]))
      end

      it 'returns a FileLink with #origin_permission :not_allowed' do
        expect(subject.success).to be_truthy
        expect(subject.result.first.origin_permission).to be :not_allowed
      end
    end

    context 'with two file links, one updated and other not allowed' do
      let(:file_info_one) { build(:storage_file_info) }
      let(:file_info_two) { build(:storage_file_info, status_code: 403) }

      let(:file_link_one) { create(:file_link, origin_id: file_info_one.id, storage: storage_one, container: work_package) }
      let(:file_link_two) { create(:file_link, origin_id: file_info_two.id, storage: storage_two, container: work_package) }

      let(:file_links) { [file_link_one, file_link_two] }

      before do
        allow(files_info_query).to receive(:call).and_return(ServiceResult.success(result: [file_info_one, file_info_two]))
      end

      it 'returns a successful result with two file links with different permissions' do
        expect(subject.success).to be_truthy
        expect(subject.result.count).to be 2
        expect(subject.result[0].origin_id).to eql file_info_one.id
        expect(subject.result[1].origin_id).to eql file_info_two.id
        expect(subject.result[0].origin_permission).to be :view
        expect(subject.result[1].origin_permission).to be :not_allowed
      end
    end

    context 'when file was not found (404)' do
      let(:file_info) { build(:storage_file_info, status_code: 404) }
      let(:file_link_one) { create(:file_link, origin_id: file_info.id, storage: storage_one, container: work_package) }

      before do
        allow(files_info_query).to receive(:call).and_return(ServiceResult.success(result: [file_info]))
      end

      it 'deletes the file link' do
        expect(subject.success).to be_truthy
        expect(subject.result.count).to be 0
        expect(Storages::FileLink.all.count).to be 0
      end
    end

    context 'when file has a different error (555)' do
      let(:file_info) { build(:storage_file_info, status_code: 555) }
      let(:file_link_one) { create(:file_link, origin_id: file_info.id, storage: storage_one, container: work_package) }

      before do
        allow(files_info_query).to receive(:call).and_return(ServiceResult.success(result: [file_info]))
      end

      it 'returns the file link with a permission set to :error' do
        expect(subject.success).to be_truthy
        expect(subject.result.count).to be 1
        expect(Storages::FileLink.all.count).to be 1
        expect(subject.result.first.origin_permission).to be :error
      end
    end

    context 'with files_info_query failing' do
      before do
        allow(files_info_query).to receive(:call).and_return(
          ServiceResult.failure(result: :error, errors: Storages::StorageError.new(code: :error))
        )
      end

      it 'leaves the list of file_links unchanged with permissions = :error' do
        expect(subject.success).to be_truthy
        expect(subject.result.first.origin_permission).to be :error
      end
    end

    context 'with file trashed in storage' do
      let(:file_info) { build(:storage_file_info, trashed: true) }
      let(:file_link_one) { create(:file_link, origin_id: file_info.id, storage: storage_one, container: work_package) }

      before do
        allow(files_info_query).to receive(:call).and_return(ServiceResult.success(result: [file_info]))
      end

      it 'returns an empty list of FileLinks' do
        expect(subject).to be_a ServiceResult
        expect(subject.success).to be_truthy
        expect(subject.result.length).to be 0
      end
    end
  end
end
