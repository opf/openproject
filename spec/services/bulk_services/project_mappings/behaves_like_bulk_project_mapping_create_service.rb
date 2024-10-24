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

RSpec.shared_examples "BulkServices project mappings create service" do
  let(:model_mapping_class) { raise("Please define the model mapping class") }
  let(:model_foreign_key_id) { raise("Please define the model foreign key id") }
  let(:required_permission) { raise("Please define the required permission for the bulk create action") }
  let(:model) { raise("Please define the model that will be linked to projects") }

  context "with admin permissions" do
    let(:user) { create(:admin) }

    context "with a single project" do
      let(:project) { create(:project) }
      let(:instance) { described_class.new(user:, projects: [project], model:) }

      it "creates the mappings" do
        expect { instance.call }.to change(model_mapping_class, :count).by(1)

        aggregate_failures "creates the mapping for the correct project and custom field" do
          expect(model_mapping_class.where(model_foreign_key_id => model.id).pluck(:project_id)).to contain_exactly(project.id)
        end
      end
    end

    context "with subprojects" do
      let(:projects) { create_list(:project, 2) }
      let!(:subproject) { create(:project, parent: projects.first) }
      let!(:subproject2) { create(:project, parent: subproject) }

      it "creates the mappings for the project and sub-projects" do
        create_service = described_class.new(user:, projects: projects.map(&:reload), model:,
                                             include_sub_projects: true)

        expect { create_service.call }.to change(model_mapping_class, :count).by(4)

        aggregate_failures "creates the mapping for the correct project and custom field" do
          expect(model_mapping_class.where(model_foreign_key_id => model.id).pluck(:project_id))
            .to contain_exactly(*projects.map(&:id), subproject.id, subproject2.id)
        end
      end
    end

    context "with multiple projects including subprojects" do
      let(:project) { create(:project) }
      let!(:subproject) { create(:project, parent: project) }

      it "creates the mappings for the project and sub-projects" do
        create_service = described_class.new(user:, projects: [project.reload, subproject], model:,
                                             include_sub_projects: true)

        expect { create_service.call }.to change(model_mapping_class, :count).by(2)

        aggregate_failures "creates the mapping for the correct project and custom field" do
          expect(model_mapping_class.where(model_foreign_key_id => model.id).pluck(:project_id))
            .to contain_exactly(project.id, subproject.id)
        end
      end
    end

    context "with duplicates" do
      let(:project) { create(:project) }
      let(:instance) { described_class.new(user:, projects: [project, project], model:) }

      it "creates the mappings only once" do
        expect { instance.call }.to change(model_mapping_class, :count).by(1)

        aggregate_failures "creates the mapping for the correct project and custom field" do
          expect(model_mapping_class.where(model_foreign_key_id => model.id).pluck(:project_id))
            .to contain_exactly(project.id)
        end
      end
    end
  end

  context "with non-admin but sufficient permissions" do
    let(:user) do
      create(:user,
             member_with_permissions: {
               project => %w[
                 view_work_packages
                 edit_project
               ].push(required_permission)
             })
    end

    let(:project) { create(:project) }
    let(:instance) { described_class.new(user:, projects: [project], model:) }

    it "creates the mappings" do
      expect { instance.call }.to change(model_mapping_class, :count).by(1)

      aggregate_failures "creates the mapping for the correct project and custom field" do
        expect(model_mapping_class.where(model_foreign_key_id => model.id).pluck(:project_id)).to contain_exactly(project.id)
      end
    end
  end

  context "without sufficient permissions" do
    let(:user) do
      create(:user,
             member_with_permissions: {
               project => %w[
                 view_work_packages
                 edit_project
               ]
             })
    end
    let(:project) { create(:project) }
    let(:instance) { described_class.new(user:, projects: [project], model:) }

    it "does not create the mappings" do
      expect { instance.call }.not_to change(model_mapping_class, :count)
      expect(instance.call).to be_failure
    end
  end

  context "with empty projects" do
    let(:user) { create(:admin) }
    let(:instance) { described_class.new(user:, projects: [], model:) }

    it "does not create the mappings" do
      service_result = instance.call
      expect(service_result).to be_failure
      expect(service_result.errors).to eq("not found")
    end
  end

  context "with archived projects" do
    let(:user) { create(:admin) }
    let(:archived_project) { create(:project, active: false) }
    let(:active_project) { create(:project) }

    let(:instance) { described_class.new(user:, projects: [archived_project, active_project], model:) }

    it "only creates mappins for the active project" do
      expect { instance.call }.to change(model_mapping_class, :count).by(1)

      aggregate_failures "creates the mapping for the correct project and custom field" do
        expect(model_mapping_class.where(model_foreign_key_id => model.id).pluck(:project_id))
          .to contain_exactly(active_project.id)
      end
    end
  end
end
