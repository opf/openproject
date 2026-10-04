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

require_relative "../../../spec_helper"

RSpec.describe Admin::Departments::ChangeParentDialogComponent, type: :component do
  let(:moved) { create(:department, lastname: "Moved") }
  let(:managed) { create(:department, lastname: "Managed") }
  let(:manual) { create(:department, lastname: "Manual") }

  before do
    moved
    manual
    create(:ldap_synchronized_department, group: managed)
  end

  it "disables LDAP-managed departments as parent candidates" do
    departments = Group.organizational_units.with_detail.in_tree_order

    render_inline(described_class.new(department: moved, departments:))

    expect(page).to have_css("[data-value='#{managed.id}'][aria-disabled='true']")
    expect(page).to have_css("[data-value='#{manual.id}']")
    expect(page).to have_no_css("[data-value='#{manual.id}'][aria-disabled='true']")
  end
end
