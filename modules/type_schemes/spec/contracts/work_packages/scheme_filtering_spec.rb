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

# frozen_string_literal: true

require "spec_helper"

RSpec.describe WorkPackages::CreateContract, "scheme filtering" do
  let(:epic)  { create(:type) }
  let(:story) { create(:type) }
  let(:bug)   { create(:type) }
  let(:project) { create(:project, types: [epic, story, bug]) }
  let(:user) { create(:user, member_with_permissions: { project => %i[view_work_packages add_work_packages] }) }

  before do
    ProjectTypeScheme.create!(project:, scheme: create(:type_scheme, types: [story, epic]))
  end

  def contract_for(wp) = described_class.new(wp, user)

  it "limits assignable types, default first" do
    wp = build(:work_package, project:, type: story)
    expect(contract_for(wp).assignable_types.to_a).to eq([story, epic])
  end

  it "rejects a new work package with a type outside the scheme" do
    wp = build(:work_package, project:, type: bug, author: user)
    contract = contract_for(wp)
    expect(contract).not_to be_valid
    expect(contract.errors.symbols_for(:type_id)).to include(:not_in_scheme)
  end

  it "keeps existing work packages editable and keeps their own type allowed" do
    wp = create(:work_package, project:, type: bug)
    wp.subject = "changed"
    c = WorkPackages::UpdateContract.new(wp, user)
    expect(c.assignable_types.to_a).to include(bug)
    c.validate
    expect(c.errors.symbols_for(:type_id)).not_to include(:not_in_scheme)
  end
end
