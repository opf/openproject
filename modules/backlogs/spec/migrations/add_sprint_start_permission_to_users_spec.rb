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
require Rails.root.join("modules/backlogs/db/migrate/20260330134729_add_sprint_start_permission_to_users")

RSpec.describe AddSprintStartPermissionToUsers, type: :model do
  subject(:migrate) { ActiveRecord::Migration.suppress_messages { described_class.migrate(:up) } }

  let!(:role_with_all) do
    create(:project_role, permissions: %i[create_sprints manage_board_views manage_sprint_items])
  end
  let!(:role_with_partial) do
    create(:project_role, permissions: %i[create_sprints manage_board_views])
  end
  let!(:role_without_any) { create(:project_role) }

  it "grants start_complete_sprint only to roles fulfilling all required permissions" do
    migrate

    expect(role_with_all.reload.permissions).to include(:start_complete_sprint)
    expect(role_with_partial.reload.permissions).not_to include(:start_complete_sprint)
    expect(role_without_any.reload.permissions).not_to include(:start_complete_sprint)
  end
end
