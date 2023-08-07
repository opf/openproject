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
require_module_spec_helper
require 'services/base_services/behaves_like_delete_service'
require_relative 'shared_event_gun_examples'

RSpec.describe Storages::ProjectStorages::DeleteService, type: :model, webmock: true do
  context 'with records written to DB' do
    let(:user) { create(:user) }
    let(:role) { create(:existing_role, permissions: [:manage_storages_in_project]) }
    let(:project) { create(:project, members: { user => role }) }
    let(:other_project) { create(:project) }
    let(:storage) { create(:storage) }
    let(:project_storage) { create(:project_storage, project:, storage:) }
    let(:work_package) { create(:work_package, project:) }
    let(:other_work_package) { create(:work_package, project: other_project) }
    let(:file_link) { create(:file_link, container: work_package, storage:) }
    let(:other_file_link) { create(:file_link, container: other_work_package, storage:) }
    let(:delete_folder_url) do
      "#{storage.host}/remote.php/dav/files/#{storage.username}/#{project_storage.project_folder_path.chop}"
    end

    it 'destroys the record' do
      project_storage
      described_class.new(model: project_storage, user:).call

      expect(Storages::ProjectStorage.where(id: project_storage.id)).not_to exist
    end

    it 'deletes all FileLinks that belong to containers of the related project' do
      file_link
      other_file_link

      described_class.new(model: project_storage, user:).call

      expect(Storages::FileLink.where(id: file_link.id)).not_to exist
      expect(Storages::FileLink.where(id: other_file_link.id)).to exist
    end

    context 'with Nextcloud storage' do
      let(:storage) { create(:nextcloud_storage) }
      let(:delete_folder_url) do
        "#{storage.host}/remote.php/dav/files/#{storage.username}/#{project_storage.project_folder_path.chop}"
      end
      let(:delete_folder_stub) do
        stub_request(:delete, delete_folder_url).to_return(status: 204, body: nil, headers: {})
      end

      before { delete_folder_stub }

      it 'tries to remove the project folder at the external nextcloud storage' do
        expect(described_class.new(model: project_storage, user:).call).to be_success
        expect(delete_folder_stub).to have_been_requested
      end

      context 'if project folder deletion request fails' do
        let(:delete_folder_stub) do
          stub_request(:delete, delete_folder_url).to_return(status: 404, body: nil, headers: {})
        end

        it 'tries to remove the project folder at the external nextcloud storage and still succeed with deletion' do
          expect(described_class.new(model: project_storage, user:).call).to be_success
          expect(delete_folder_stub).to have_been_requested
        end
      end
    end
  end

  it_behaves_like 'BaseServices delete service' do
    let(:factory) { :project_storage }

    it_behaves_like('an event gun', OpenProject::Events::PROJECT_STORAGE_DESTROYED)
  end
end
