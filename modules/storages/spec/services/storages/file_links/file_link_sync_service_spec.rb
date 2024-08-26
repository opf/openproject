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

RSpec.describe Storages::FileLinkSyncService, type: :model do
  let(:user) { create(:user) }
  let(:role) { create(:project_role, permissions: [:manage_file_links]) }
  let(:project) { create(:project, members: { user => role }) }
  let(:work_package) { create(:work_package, project:) }

  let(:storage_one) { create(:nextcloud_storage, host: "https://host-1.example.org") }
  let(:storage_two) { create(:nextcloud_storage, host: "https://host-2.example.org") }

  let(:file_link_one) { create(:file_link, storage: storage_one, container: work_package) }
  let(:file_link_two) { create(:file_link, storage: storage_two, container: work_package) }

  let(:file_links) { [file_link_one] }

  subject(:service) { described_class.new(user:).call(file_links) }

  describe "#call" do
    context "with one file link" do
      let(:file_info) { build(:storage_file_info) }
      let(:file_link_one) { create(:file_link, origin_id: file_info.id, storage: storage_one, container: work_package) }

      before do
        Storages::Peripherals::Registry
          .stub("nextcloud.queries.files_info", ->(_) { ServiceResult.success(result: [file_info]) })
      end

      it "updates all origin_* fields" do
        expect(service.success).to be_truthy
        expect(service.result.count).to be 1
        expect(service.result.first).to be_a Storages::FileLink

        expect(service.result.first.origin_id).to eql file_info.id
        expect(service.result.first.origin_created_at).to eql file_info.created_at
        expect(service.result.first.origin_updated_at).to eql file_info.last_modified_at
        expect(service.result.first.origin_mime_type).to eql file_info.mime_type
        expect(service.result.first.origin_name).to eql file_info.name
        expect(service.result.first.origin_created_by_name).to eql file_info.owner_name
      end
    end

    context "without permission to read file (403)" do
      let(:file_info) { build(:storage_file_info, status_code: 403) }
      let(:file_link_one) { create(:file_link, origin_id: file_info.id, storage: storage_one, container: work_package) }

      before do
        Storages::Peripherals::Registry
          .stub("nextcloud.queries.files_info", ->(_) { ServiceResult.success(result: [file_info]) })
      end

      it "returns a FileLink with #origin_status :not_allowed" do
        expect(service.success).to be_truthy
        expect(service.result.first.origin_status).to be :view_not_allowed
      end
    end

    context "with two file links, one updated and other not allowed" do
      let(:file_info_one) { build(:storage_file_info) }
      let(:file_info_two) { build(:storage_file_info, status_code: 403) }

      let(:file_link_one) { create(:file_link, origin_id: file_info_one.id, storage: storage_one, container: work_package) }
      let(:file_link_two) { create(:file_link, origin_id: file_info_two.id, storage: storage_two, container: work_package) }

      let(:file_links) { [file_link_one, file_link_two] }

      before do
        Storages::Peripherals::Registry
          .stub("nextcloud.queries.files_info",
                ->(_) { ServiceResult.success(result: [file_info_one, file_info_two]) })
      end

      it "returns a successful result with two file links with different permissions" do
        expect(service.success).to be_truthy
        expect(service.result.count).to be 2
        expect(service.result[0].origin_id).to eql file_info_one.id
        expect(service.result[1].origin_id).to eql file_info_two.id
        expect(service.result[0].origin_status).to be :view_allowed
        expect(service.result[1].origin_status).to be :view_not_allowed
      end
    end

    context "when file was not found (404)" do
      let(:file_info) { build(:storage_file_info, status_code: 404) }
      let(:file_link_one) { create(:file_link, origin_id: file_info.id, storage: storage_one, container: work_package) }

      before do
        Storages::Peripherals::Registry
          .stub("nextcloud.queries.files_info", ->(_) { ServiceResult.success(result: [file_info]) })
      end

      it "returns the file link with a status set to :not_found" do
        expect(service.success).to be_truthy
        expect(service.result.count).to be 1
        expect(Storages::FileLink.count).to be 1
        expect(service.result.first.origin_status).to be :not_found
      end
    end

    context "when file has a different error (555)" do
      let(:file_info) { build(:storage_file_info, status_code: 555) }
      let(:file_link_one) { create(:file_link, origin_id: file_info.id, storage: storage_one, container: work_package) }

      before do
        Storages::Peripherals::Registry
          .stub("nextcloud.queries.files_info", ->(_) { ServiceResult.success(result: [file_info]) })
      end

      it "returns the file link with a status set to :error" do
        expect(service.success).to be_truthy
        expect(service.result.count).to be 1
        expect(Storages::FileLink.count).to be 1
        expect(service.result.first.origin_status).to be :error
      end
    end

    context "with files_info_query failing" do
      before do
        Storages::Peripherals::Registry
          .stub("nextcloud.queries.files_info",
                ->(_) { ServiceResult.failure(result: :error, errors: Storages::StorageError.new(code: :error)) })
      end

      it "leaves the list of file_links unchanged with permissions = :error" do
        expect(service.success).to be_truthy
        expect(service.result.first.origin_status).to be :error
      end
    end
  end
end
