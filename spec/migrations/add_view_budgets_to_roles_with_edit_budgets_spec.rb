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
require Rails.root.join("db/migrate/20260223142025_add_view_budgets_to_roles_with_edit_budgets")

RSpec.describe AddViewBudgetsToRolesWithEditBudgets, type: :model do
  describe "up migration" do
    context "when a role has edit_budgets but not view_budgets" do
      let!(:role) { create(:project_role, permissions: [:edit_budgets]) }

      it "adds view_budgets to the role" do
        expect(role.permissions).not_to include(:view_budgets)

        ActiveRecord::Migration.suppress_messages { described_class.migrate(:up) }

        role.reload
        expect(role.permissions).to include(:view_budgets)
        expect(role.permissions).to include(:edit_budgets)
      end
    end

    context "when a role already has both edit_budgets and view_budgets" do
      let!(:role) { create(:project_role, permissions: %i[edit_budgets view_budgets]) }

      it "does not duplicate view_budgets" do
        ActiveRecord::Migration.suppress_messages { described_class.migrate(:up) }

        role.reload
        expect(role.permissions.count(:view_budgets)).to eq(1)
      end
    end

    context "when a role has view_budgets but not edit_budgets" do
      let!(:role) { create(:project_role, permissions: [:view_budgets]) }

      it "does not modify the role" do
        ActiveRecord::Migration.suppress_messages { described_class.migrate(:up) }

        role.reload
        expect(role.permissions).to include(:view_budgets)
        expect(role.permissions).not_to include(:edit_budgets)
      end
    end

    context "when a role has no budget permissions" do
      let!(:role) { create(:project_role, permissions: [:view_work_packages]) }

      it "does not modify the role" do
        ActiveRecord::Migration.suppress_messages { described_class.migrate(:up) }

        role.reload
        expect(role.permissions).not_to include(:view_budgets)
        expect(role.permissions).not_to include(:edit_budgets)
      end
    end
  end
end
