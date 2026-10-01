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
require Rails.root.join("db/migrate/20260212145213_migrate_backlogs_permissions")

RSpec.describe MigrateBacklogsPermissions, type: :model do
  subject(:migrate) { ActiveRecord::Migration.suppress_messages { described_class.migrate(:up) } }

  # source permission => expected permissions after up migration.
  up_mapping = {
    view_master_backlog: %i[view_sprints],
    view_taskboards: %i[view_sprints],
    update_sprints: %i[create_sprints],
    manage_versions: %i[manage_versions create_sprints],
    assign_versions: %i[assign_versions manage_sprint_items]
  }

  # source permission => expected permissions after rollback.
  # Backlogs-specific permissions (view_master_backlog, view_taskboards, update_sprints)
  # are lost because the down migration cannot determine the original source.
  down_mapping = {
    view_master_backlog: [],
    view_taskboards: [],
    update_sprints: [],
    manage_versions: %i[manage_versions],
    assign_versions: %i[assign_versions]
  }

  let(:all_source_permissions) do
    %i(view_master_backlog
       view_taskboards
       update_sprints
       manage_versions
       assign_versions)
  end

  let!(:role) { create(:project_role, permissions:, add_public_permissions: false) }

  describe "migrating up" do
    context "with a role having no backlogs permissions" do
      let(:permissions) { [] }

      it "does not change permissions" do
        expect { migrate }.not_to change { role.reload.permissions }
      end
    end

    up_mapping.each do |source_permission, expected_permissions|
      context "with a role having only :#{source_permission} permission" do
        let(:permissions) { [source_permission] }

        it "results in #{expected_permissions}" do
          expect { migrate }
            .to change { role.reload.permissions }
            .from(contain_exactly(source_permission))
            .to(match_array(expected_permissions))
        end
      end
    end

    context "with a role combining all source permissions" do
      let(:permissions) { all_source_permissions }

      it "migrates to all new permissions plus retained core permissions" do
        expect { migrate }
          .to change { role.reload.permissions }
          .to(match_array(%i[view_sprints create_sprints manage_sprint_items manage_versions assign_versions]))
      end
    end
  end

  describe "migrating down" do
    subject(:rollback) { ActiveRecord::Migration.suppress_messages { described_class.migrate(:down) } }

    before { migrate }

    down_mapping.each do |source_permission, expected_permissions|
      context "with a role originally having only :#{source_permission} permission" do
        let(:permissions) { [source_permission] }

        it "retains #{expected_permissions.empty? ? 'no' : expected_permissions} permissions" do
          expect { rollback }
            .to change { role.reload.permissions }
            .to(match_array(expected_permissions))
        end
      end
    end

    context "with a role combining all source permissions" do
      let(:permissions) { all_source_permissions }

      it "retains only core permissions that were not deleted during up" do
        expect { rollback }
          .to change { role.reload.permissions }
          .to(match_array(%i[manage_versions assign_versions]))
      end
    end
  end
end
