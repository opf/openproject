#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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

RSpec.describe ProjectCustomFieldProjectMappings::BulkCreateService do
  shared_let(:project_custom_field) { create(:project_custom_field) }

  context "with admin permissions" do
    let(:user) { create(:admin) }

    context "with a single project" do
      let(:project) { create(:project) }
      let(:instance) { described_class.new(user:, project:, project_custom_field:) }

      it "creates the mappings" do
        expect { instance.call }.to change(ProjectCustomFieldProjectMapping, :count).by(1)

        aggregate_failures "creates the mapping for the correct project and custom field" do
          expect(ProjectCustomFieldProjectMapping.last.project).to eq(project)
          expect(ProjectCustomFieldProjectMapping.last.project_custom_field).to eq(project_custom_field)
        end
      end
    end

    context "with subprojects" do
      let(:project) { create(:project) }
      let!(:subproject) { create(:project, parent: project) }
      let!(:subproject2) { create(:project, parent: subproject) }

      it "creates the mappings for the project and sub-projects" do
        create_service = described_class.new(user:, project: project.reload, project_custom_field:,
                                             include_sub_projects: true)

        expect { create_service.call }.to change(ProjectCustomFieldProjectMapping, :count).by(3)

        aggregate_failures "creates the mapping for the correct project and custom field" do
          expect(ProjectCustomFieldProjectMapping.where(project_custom_field:).pluck(:project_id))
            .to contain_exactly(project.id, subproject.id, subproject2.id)
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
                 select_project_custom_fields
               ]
             })
    end

    let(:project) { create(:project) }
    let(:instance) { described_class.new(user:, project:, project_custom_field:) }

    it "creates the mappings" do
      expect { instance.call }.to change(ProjectCustomFieldProjectMapping, :count).by(1)

      aggregate_failures "creates the mapping for the correct project and custom field" do
        expect(ProjectCustomFieldProjectMapping.last.project).to eq(project)
        expect(ProjectCustomFieldProjectMapping.last.project_custom_field).to eq(project_custom_field)
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
    let(:instance) { described_class.new(user:, project:, project_custom_field:) }

    it "does not create the mappings" do
      expect { instance.call }.not_to change(ProjectCustomFieldProjectMapping, :count)
      expect(instance.call).to be_failure
    end
  end
end
