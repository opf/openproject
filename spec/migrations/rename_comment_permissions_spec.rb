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
require Rails.root.join("db/migrate/20250422072119_rename_comment_permissions")

RSpec.describe RenameCommentPermissions, type: :model do
  subject(:migrate) { ActiveRecord::Migration.suppress_messages { described_class.migrate(:up) } }

  let(:old_permissions) do
    %i[add_work_package_notes edit_own_work_package_notes edit_work_package_notes
       view_comments_with_restricted_visibility add_comments_with_restricted_visibility
       edit_own_comments_with_restricted_visibility edit_others_comments_with_restricted_visibility]
  end
  let(:new_permissions) do
    %i[add_work_package_comments edit_own_work_package_comments edit_work_package_comments
       view_internal_comments add_internal_comments
       edit_own_internal_comments edit_others_internal_comments]
  end

  let!(:empty_role) { create(:project_role) }
  let!(:role_with_all) do
    create(:project_role, permissions: old_permissions, add_public_permissions: false)
  end
  let!(:role_with_notes_only) do
    create(:project_role, permissions: %i[add_work_package_notes edit_own_work_package_notes], add_public_permissions: false)
  end

  describe "migrating up" do
    it "does not add permissions to a role without comment permissions" do
      expect { migrate }.not_to change { empty_role.reload.permissions }
    end

    it "renames all comment permissions" do
      expect { migrate }
        .to change { role_with_all.reload.permissions }
        .from(match_array(old_permissions))
        .to(match_array(new_permissions))
    end

    it "renames only the matching permissions" do
      expect { migrate }
        .to change { role_with_notes_only.reload.permissions }
        .from(match_array(%i[add_work_package_notes edit_own_work_package_notes]))
        .to(match_array(%i[add_work_package_comments edit_own_work_package_comments]))
    end
  end

  describe "migrating down" do
    subject(:rollback) { ActiveRecord::Migration.suppress_messages { described_class.migrate(:down) } }

    before { migrate }

    it "reverts all comment permissions" do
      expect { rollback }
        .to change { role_with_all.reload.permissions }
        .from(match_array(new_permissions))
        .to(match_array(old_permissions))
    end

    it "reverts only the matching permissions" do
      expect { rollback }
        .to change { role_with_notes_only.reload.permissions }
        .from(match_array(%i[add_work_package_comments edit_own_work_package_comments]))
        .to(match_array(%i[add_work_package_notes edit_own_work_package_notes]))
    end
  end
end
