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

RSpec.describe Storages::ProjectStorages::BulkCreateService do
  shared_let(:user) { create(:admin) }
  shared_let(:storage) { create(:nextcloud_storage, :as_automatically_managed) }

  let(:project_folder_mode) { "automatic" }

  before { allow(OpenProject::Notifications).to(receive(:send)) }

  context "with admin permissions" do
    context "with a single project" do
      let(:project) { create(:project) }
      let(:project_folder_mode) { "inactive" }
      let(:instance) { described_class.new(user:, projects: [project], storage:) }

      it "activates the storage for the given project", :aggregate_failures do
        expect { instance.call(project_folder_mode:) }
          .to change(Storages::ProjectStorage, :count).by(1)

        project_storage = Storages::ProjectStorage.last
        expect(project_storage.project).to eq(project)
        expect(project_storage.storage).to eq(storage)

        aggregate_failures "does not create last project folders for inactive project folder mode" do
          expect(project_storage.reload.last_project_folders.count).to be_zero
        end

        aggregate_failures "broadcasts projects storages created event" do
          expect(OpenProject::Notifications).to have_received(:send)
            .with(OpenProject::Events::PROJECT_STORAGE_CREATED, project_folder_mode:,
                                                                project_folder_mode_previously_was: nil, storage:)
        end
      end
    end

    context "with subprojects" do
      let(:projects) { create_list(:project, 2) }
      let!(:subproject) { create(:project, parent: projects.first) }
      let!(:subproject2) { create(:project, parent: subproject) }

      it "activates the storage for the project and sub-projects", :aggregate_failures do
        create_service = described_class.new(user:, projects: projects.map(&:reload), storage:,
                                             include_sub_projects: true)

        expect { create_service.call(project_folder_mode:) }
          .to change(Storages::ProjectStorage, :count).by(4)
          .and change(Storages::LastProjectFolder, :count).by(4)

        expect(Storages::ProjectStorage.where(storage:).pluck(:project_id))
          .to contain_exactly(*projects.map(&:id), subproject.id, subproject2.id)

        aggregate_failures "broadcasts projects storages created event" do
          expect(OpenProject::Notifications).to have_received(:send)
            .with(OpenProject::Events::PROJECT_STORAGE_CREATED, project_folder_mode:,
                                                                project_folder_mode_previously_was: nil, storage:)
        end
      end
    end

    context "with multiple projects including subprojects" do
      let(:project) { create(:project) }
      let!(:subproject) { create(:project, parent: project) }

      it "activates the storage for the project and sub-projects" do
        create_service = described_class.new(user:, projects: [project.reload, subproject], storage:,
                                             include_sub_projects: true)

        expect { create_service.call(project_folder_mode:) }
          .to change(Storages::ProjectStorage, :count).by(2)
          .and change(Storages::LastProjectFolder, :count).by(2)

        expect(Storages::ProjectStorage.where(storage:).pluck(:project_id))
          .to contain_exactly(project.id, subproject.id)

        aggregate_failures "broadcasts projects storages created event" do
          expect(OpenProject::Notifications).to have_received(:send)
            .with(OpenProject::Events::PROJECT_STORAGE_CREATED, project_folder_mode:,
                                                                project_folder_mode_previously_was: nil, storage:)
        end
      end
    end

    context "with duplicates" do
      let(:project) { create(:project) }

      it "activates the storage only once" do
        create_service = described_class.new(user:, projects: [project, project], storage:)

        expect { create_service.call(project_folder_mode:) }
          .to change(Storages::ProjectStorage, :count).by(1)
          .and change(Storages::LastProjectFolder, :count).by(1)

        project_storage = Storages::ProjectStorage.last
        expect(project_storage.project).to eq(project)
        expect(project_storage.storage).to eq(storage)

        aggregate_failures "broadcasts projects storages created event" do
          expect(OpenProject::Notifications).to have_received(:send)
            .with(OpenProject::Events::PROJECT_STORAGE_CREATED, project_folder_mode:,
                                                                project_folder_mode_previously_was: nil, storage:)
        end
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

    let(:project) { create(:project) }
    let(:project_folder_mode) { "inactive" }

    it "activates the storage" do
      create_service = described_class.new(user:, projects: [project], storage:)

      expect { create_service.call(project_folder_mode:) }
        .to change(Storages::ProjectStorage, :count).by(1)

      project_storage = Storages::ProjectStorage.last
      expect(project_storage.project).to eq(project)
      expect(project_storage.storage).to eq(storage)

      aggregate_failures "broadcasts projects storages created event" do
        expect(OpenProject::Notifications).to have_received(:send)
          .with(OpenProject::Events::PROJECT_STORAGE_CREATED, project_folder_mode:,
                                                              project_folder_mode_previously_was: nil, storage:)
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
    let(:project) { create(:project) }
    let(:project_folder_mode) { "inactive" }
    let(:instance) { described_class.new(user:, projects: [project], storage:) }

    it "does not create any project storages" do
      expect { instance.call(project_folder_mode:) }.not_to change(Storages::ProjectStorage, :count)
      expect(instance.call).to be_failure
      expect(OpenProject::Notifications).not_to have_received(:send)
        .with(OpenProject::Events::PROJECT_STORAGE_CREATED, project_folder_mode:,
                                                            project_folder_mode_previously_was: nil, storage:)
    end
  end

  context "with empty projects" do
    let(:instance) { described_class.new(user:, projects: [], storage:) }

    it "does not create any project storages" do
      service_result = instance.call(project_folder_mode:)
      expect(service_result).to be_failure
      expect(service_result.errors).to eq("not found")
      expect(OpenProject::Notifications).not_to have_received(:send)
    end
  end

  context "with archived projects" do
    let(:archived_project) { create(:project, active: false) }
    let(:active_project) { create(:project) }

    it "only creates the project storage for the active project", :aggregate_failures do
      create_service = described_class.new(user:, projects: [archived_project, active_project], storage:)

      expect { create_service.call(project_folder_mode:) }
        .to change(Storages::ProjectStorage, :count).by(1)
        .and change(Storages::LastProjectFolder, :count).by(1)

      expect(Storages::ProjectStorage.where(storage:).pluck(:project_id))
        .to contain_exactly(active_project.id)

      aggregate_failures "broadcasts projects storages created event" do
        expect(OpenProject::Notifications).to have_received(:send)
          .with(OpenProject::Events::PROJECT_STORAGE_CREATED, project_folder_mode:,
                                                              project_folder_mode_previously_was: nil, storage:)
      end
    end
  end

  context "with broken contract" do
    let(:storage) { create(:nextcloud_storage, :as_not_automatically_managed) }
    let(:project) { create(:project) }

    it "does not create any records" do
      create_service = described_class.new(user:, projects: [project], storage:)
      result = nil

      aggregate_failures "automatic mode cannot be used with non-automatically managed storage" do
        expect { result = create_service.call(project_folder_mode: "automatic") }
          .not_to change(Storages::ProjectStorage, :count)
        expect(result).to be_failure
        expect(result.errors.full_messages.to_sentence)
          .to eq("Project folder mode is not available for this storage.")
      end

      aggregate_failures "manual mode requires a project folder id" do
        expect { result = create_service.call(project_folder_mode: "manual") }
          .not_to change(Storages::ProjectStorage, :count)
        expect(result).to be_failure
        expect(result.errors.messages).to eq({ project_folder_id: ["Please select a folder."] })
      end
    end
  end
end
