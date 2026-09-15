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

RSpec.describe Queries::Statuses::StatusQuery do
  shared_let(:user) { create(:admin) }

  shared_let(:task) { create(:type, name: "Task") }
  shared_let(:bug) { create(:type, name: "Bug") }
  shared_let(:manager) { create(:project_role, name: "Manager") }
  shared_let(:member) { create(:project_role, name: "Member") }

  shared_let(:new_status) { create(:status, name: "New") }
  shared_let(:in_progress) { create(:status, name: "In progress") }
  shared_let(:rejected) { create(:status, name: "Rejected") }
  shared_let(:unused) { create(:status, name: "Unused") }

  shared_let(:task_manager_transition) do
    create(:workflow, type: task, role: manager, old_status: new_status, new_status: in_progress)
  end
  shared_let(:bug_member_transition) do
    create(:workflow, type: bug, role: member, old_status: rejected, new_status: new_status)
  end

  subject(:query) { described_class.new(user:) }

  def results_for(types: [], roles: [])
    query.where("type", "=", types.map { it.id.to_s }) if types.any?
    query.where("role", "=", roles.map { it.id.to_s }) if roles.any?
    query.results
  end

  it "returns every status when nothing is filtered" do
    expect(results_for).to contain_exactly(new_status, in_progress, rejected, unused)
  end

  it "returns statuses on either side of a transition" do
    expect(results_for(types: [task], roles: [manager])).to contain_exactly(new_status, in_progress)
  end

  it "filters on the type alone" do
    expect(results_for(types: [bug])).to contain_exactly(rejected, new_status)
  end

  it "filters on the role alone" do
    expect(results_for(roles: [manager])).to contain_exactly(new_status, in_progress)
  end

  it "unions the selected types and roles" do
    expect(results_for(types: [task, bug], roles: [manager, member]))
      .to contain_exactly(new_status, in_progress, rejected)
  end

  it "matches a type and a role only when the same workflow pairs them" do
    # Task/Manager and Bug/Member exist; Task/Member does not, so nothing matches it
    # even though both sides are used elsewhere.
    expect(results_for(types: [task], roles: [member])).to be_empty
  end

  it "returns a status once however many transitions name it" do
    create(:workflow, type: task, role: manager, old_status: in_progress, new_status: new_status)

    expect(results_for(types: [task], roles: [manager]).to_a.size).to eq(2)
  end

  it "returns nothing for a type that has no variants to reach a workflow through" do
    variantless = create(:type, name: "Variantless")
    TypeVariant.where(type_id: variantless.id).delete_all

    expect(results_for(types: [variantless])).to be_empty
  end
end
