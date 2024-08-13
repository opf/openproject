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

RSpec.describe Storages::LastProjectFolders::BulkCreateService do
  subject(:create_service) { described_class.new(user:, project_storages:) }

  shared_association_default(:storage) { create(:nextcloud_storage) }
  shared_association_default(:project) { create(:project) }
  shared_let(:project_storages) { create_list(:project_storage, 5, project_folder_mode: "automatic") }
  shared_let(:user) { create(:admin) }

  context "with admin permissions" do
    it "creates the corresponding last project folders", :aggregate_failures do
      expect { create_service.call }
        .to change(Storages::LastProjectFolder, :count).by(project_storages.size)

      project_storages.each do |project_storage|
        last_project_folders = project_storage.reload.last_project_folders
        expect(last_project_folders.count).to eq(1)
        expect(last_project_folders.pluck(:origin_folder_id, :mode))
          .to eq([[project_storage.project_folder_id, project_storage.project_folder_mode]])
      end
    end
  end

  context "with non-admin but sufficient permissions" do
    let(:user) do
      create(:user,
             member_with_permissions: {
               project => %w[view_work_packages
                             edit_project
                             manage_files_in_project]
             })
    end

    it "creates the corresponding last project folders", :aggregate_failures do
      expect { create_service.call }
        .to change(Storages::LastProjectFolder, :count).by(project_storages.size)

      project_storages.each do |project_storage|
        last_project_folders = project_storage.reload.last_project_folders
        expect(last_project_folders.count).to eq(1)
        expect(last_project_folders.pluck(:origin_folder_id, :mode))
          .to eq([[project_storage.project_folder_id, project_storage.project_folder_mode]])
      end
    end
  end

  context "without sufficient permissions" do
    let(:user) do
      create(:user,
             member_with_permissions: {
               project => %w[view_work_packages
                             edit_project]
             })
    end

    it "does not create any records" do
      expect { create_service.call }.not_to change(Storages::LastProjectFolder, :count)
      expect(create_service.call).to be_failure
    end
  end

  context "with empty projects storages" do
    let(:project_storages) { [] }

    it "does not create any project storages" do
      service_result = create_service.call
      expect(service_result).to be_failure
      expect(service_result.errors).to eq("not found")
    end
  end

  context "with broken contract" do
    let(:project_storages) { create_list(:project_storage, 2, project_folder_mode: "inactive") }

    it "does not create any records" do
      expect { create_service.call }.not_to change(Storages::LastProjectFolder, :count)
      expect(create_service.call).to be_failure
    end
  end
end
