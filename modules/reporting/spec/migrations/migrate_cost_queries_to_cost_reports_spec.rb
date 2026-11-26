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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"
require Rails.root.join("modules/reporting/db/migrate/20260814153519_migrate_cost_queries_to_cost_reports")

RSpec.describe MigrateCostQueriesToCostReports, type: :model do
  subject(:migrate) { ActiveRecord::Migration.suppress_messages { described_class.migrate(:up) } }

  let(:user) { create(:user) }
  let(:project) { create(:project) }
  let(:serialized) { { filters: [], group_bys: [] }.to_yaml }

  context "when a cost query references a project that no longer exists" do
    let(:deleted_project_id) { project.id }

    let!(:orphaned_cost_query) do
      described_class::MigrationCostQuery.create!(name: "Orphaned", user_id: user.id, project_id: deleted_project_id, serialized:)
    end
    let!(:valid_cost_query) do
      described_class::MigrationCostQuery.create!(name: "Valid", user_id: user.id, project_id: create(:project).id, serialized:)
    end

    before { Project.where(id: deleted_project_id).delete_all }

    it "does not fail" do
      expect { migrate }.not_to raise_error
    end

    it "migrates only the cost query whose project still exists" do
      migrate

      expect(described_class::PersistedView.where(type: "CostReport").pluck(:name)).to contain_exactly("Valid")
    end
  end

  context "when a cost query references a user that no longer exists" do
    let(:deleted_user_id) { user.id + 1 }

    let!(:orphaned_cost_query) do
      described_class::MigrationCostQuery.create!(name: "Orphaned", user_id: deleted_user_id, project_id: project.id, serialized:)
    end
    let!(:valid_cost_query) do
      described_class::MigrationCostQuery.create!(name: "Valid", user_id: user.id, project_id: project.id, serialized:)
    end

    it "does not fail" do
      expect { migrate }.not_to raise_error
    end

    it "migrates only the cost query whose user still exists" do
      migrate

      expect(described_class::PersistedView.where(type: "CostReport").pluck(:name)).to contain_exactly("Valid")
    end
  end
end
