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
require Rails.root.join("db/migrate/20260911130000_remove_select_custom_fields_permission_from_roles")

RSpec.describe RemoveSelectCustomFieldsPermissionFromRoles, type: :model do
  subject(:migrate) { ActiveRecord::Migration.suppress_messages { described_class.migrate(:up) } }

  let!(:selecting_role) do
    create(:project_role, permissions: %i[view_project select_custom_fields], add_public_permissions: false)
  end
  let!(:other_role) { create(:project_role, permissions: %i[view_project], add_public_permissions: false) }

  it "lets a role that selected custom fields manage the project's type variants instead" do
    expect { migrate }
      .to change { selecting_role.reload.permissions }
      .from(match_array(%i[view_project select_custom_fields]))
      .to(match_array(%i[view_project manage_project_variants]))
  end

  it "leaves a role that did not select custom fields alone" do
    expect { migrate }.not_to change { other_role.reload.permissions }
  end
end
