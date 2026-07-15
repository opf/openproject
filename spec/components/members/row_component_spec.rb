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

require "rails_helper"

RSpec.describe Members::RowComponent, type: :component do
  shared_let(:project) { create(:project) }
  shared_let(:role) { create(:project_role) }

  shared_let(:user) { create(:user) }
  shared_let(:department) { create(:department, lastname: "Finance", members: [user]) }
  shared_let(:regular_group) { create(:group, lastname: "A-Team", members: [user]) }

  shared_let(:member) { create(:member, principal: user, project:, roles: [role]) }

  before do
    # Both groups need to be members of the project to show up in the user's "Groups" column.
    create(:member, principal: department, project:, roles: [role])
    create(:member, principal: regular_group, project:, roles: [role])
  end

  let(:table) do
    instance_double(Members::TableComponent,
                    columns: [:groups],
                    project:,
                    authorize_update: false,
                    authorize_delete: false,
                    authorize_work_package_shares_view: false,
                    authorize_work_package_shares_delete: false,
                    authorize_manage_user: false,
                    hide_roles?: true)
  end

  subject(:rendered) { render_inline(described_class.new(row: member, table:)) }

  it "marks departments with a briefcase icon but leaves regular groups unmarked" do
    expect(rendered).to have_css("td.groups", text: "Finance")
    expect(rendered).to have_css("td.groups", text: "A-Team")

    # Exactly one briefcase: the department, not the regular group.
    expect(rendered).to have_css("td.groups .octicon-briefcase", count: 1)
    expect(rendered).to have_css("td.groups [aria-label='Organizational unit']", count: 1)
  end
end
