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

require_relative "../spec_helper"

RSpec.describe CostType, "disabling for_all_projects" do
  subject(:disable_for_all) { cost_type.update!(for_all_projects: false) }

  shared_let(:cost_type) { create(:cost_type, for_all_projects: true) }
  shared_let(:project_with_costs) { create(:project) }

  def log_costs_in(project, type: cost_type)
    work_package = create(:work_package, project:)
    create(:cost_entry, cost_type: type, entity: work_package)
  end

  it "enables the cost type in projects that already logged costs for it" do
    log_costs_in(project_with_costs)

    expect { disable_for_all }
      .to change { CostTypesProject.where(cost_type:, project: project_with_costs).count }
      .from(0).to(1)
  end

  it "does not enable it in projects without logged costs" do
    other_project = create(:project)
    log_costs_in(project_with_costs)

    disable_for_all

    expect(CostTypesProject.where(cost_type:, project: other_project)).not_to exist
  end

  it "ignores costs logged for a different cost type" do
    log_costs_in(project_with_costs, type: create(:cost_type, for_all_projects: true))

    disable_for_all

    expect(CostTypesProject.where(cost_type:, project: project_with_costs)).not_to exist
  end

  it "does not enable it in archived projects" do
    log_costs_in(project_with_costs)
    project_with_costs.update!(active: false)

    disable_for_all

    expect(CostTypesProject.where(cost_type:, project: project_with_costs)).not_to exist
  end

  it "does not create mappings when re-enabling for_all_projects" do
    log_costs_in(project_with_costs)

    expect { cost_type.update!(for_all_projects: true) }
      .not_to change(CostTypesProject, :count)
  end

  context "when a mapping already exists (disabled, re-enabled, disabled again)" do
    before do
      log_costs_in(project_with_costs)
      cost_type.update!(for_all_projects: false) # creates the mapping
      cost_type.update!(for_all_projects: true)  # no-op, mapping remains
    end

    it "does not raise a uniqueness error and keeps a single mapping" do
      expect { disable_for_all }.not_to raise_error
      expect(CostTypesProject.where(cost_type:, project: project_with_costs).count).to eq(1)
    end
  end
end
