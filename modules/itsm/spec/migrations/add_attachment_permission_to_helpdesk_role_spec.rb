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
require Rails.root.join("modules/itsm/db/migrate/20261124100000_add_attachment_permission_to_helpdesk_role")

RSpec.describe AddAttachmentPermissionToHelpdeskRole, type: :model do
  let!(:helpdesk_role) do
    ITSM::HelpdeskRole.create!(name: "Help desk", permissions: %i[view_work_packages add_work_packages add_work_package_comments])
  end
  let!(:other_role) { create(:project_role, permissions: %i[add_work_package_comments]) }

  def migrate(direction) = ActiveRecord::Migration.suppress_messages { described_class.migrate(direction) }

  it "lets the help desk role add attachments" do
    migrate(:up)

    expect(helpdesk_role.reload.permissions).to include(:add_work_package_attachments)
    expect(other_role.reload.permissions).not_to include(:add_work_package_attachments)
  end

  it "adds the permission once when run again" do
    2.times { migrate(:up) }

    expect(RolePermission.where(role: helpdesk_role, permission: "add_work_package_attachments").count).to eq(1)
  end

  it "removes the permission again when rolled back" do
    migrate(:up)
    migrate(:down)

    expect(helpdesk_role.reload.permissions).not_to include(:add_work_package_attachments)
  end
end
