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
require Rails.root.join("modules/overviews/db/migrate/20250910085916_rename_manage_overview_to_manage_dashboards")

RSpec.describe RenameManageOverviewToManageDashboards, type: :model do
  subject(:migrate) { ActiveRecord::Migration.suppress_messages { described_class.migrate(:up) } }

  let!(:empty_role) { create(:project_role) }
  let!(:role_with_permission) do
    create(:project_role, permissions: %i[manage_overview], add_public_permissions: false)
  end

  describe "migrating up" do
    it "does not add permissions to a role without manage_overview" do
      expect { migrate }.not_to change { empty_role.reload.permissions }
    end

    it "renames manage_overview to manage_dashboards" do
      expect { migrate }
        .to change { role_with_permission.reload.permissions }
        .from(match_array(%i[manage_overview]))
        .to(match_array(%i[manage_dashboards]))
    end
  end

  describe "migrating down" do
    subject(:rollback) { ActiveRecord::Migration.suppress_messages { described_class.migrate(:down) } }

    before { migrate }

    it "reverts manage_dashboards to manage_overview" do
      expect { rollback }
        .to change { role_with_permission.reload.permissions }
        .from(match_array(%i[manage_dashboards]))
        .to(match_array(%i[manage_overview]))
    end
  end
end
