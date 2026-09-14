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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require_relative "../../../spec_helper"
require Rails.root.join("spec/services/bulk_services/project_mappings/behaves_like_bulk_project_mapping_create_service")

RSpec.describe CostTypes::CostTypeProjects::BulkCreateService do
  shared_let(:cost_type) { create(:cost_type, for_all_projects: false) }

  it_behaves_like "BulkServices project mappings create service" do
    let(:model) { cost_type }
    let(:model_mapping_class) { CostTypesProject }
    let(:model_foreign_key_id) { :cost_type_id }
    let(:required_permission) { :manage_project_activities }
    # Cost types must stay enabled in archived projects that already logged costs.
    let(:maps_archived_projects) { true }
  end

  context "with only an archived project" do
    let(:archived_project) { create(:project, active: false) }

    subject(:service_result) do
      described_class.new(user:, projects: [archived_project], model: cost_type, include_sub_projects: false).call
    end

    context "as an admin" do
      let(:user) { create(:admin) }

      it "creates the mapping" do
        expect { service_result }.to change { CostTypesProject.where(cost_type:, project: archived_project).count }
          .from(0).to(1)
        expect(service_result).to be_success
      end
    end

    context "as a non-admin with manage permission" do
      let(:user) { create(:user, member_with_permissions: { archived_project => %i[manage_project_activities] }) }

      it "refuses to create the mapping" do
        expect { service_result }.not_to change(CostTypesProject, :count)
        expect(service_result).to be_failure
      end
    end
  end
end
