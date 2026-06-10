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

RSpec.describe ResourcePlanners::SetAttributesService, type: :model do
  shared_let(:project) { create(:project) }
  shared_let(:user) { create(:user, member_with_permissions: { project => %i[view_resource_planners] }) }

  let(:model) { ResourcePlanner.new }
  let(:contract_class) { ResourcePlanners::CreateContract }
  let(:params) { { name: "My planner", project: } }

  subject(:service_call) do
    described_class.new(user:, model:, contract_class:).call(params)
  end

  it "assigns the given attributes" do
    service_call
    expect(model.name).to eq("My planner")
    expect(model.project).to eq(project)
  end

  it "always assigns the calling user as principal, ignoring any caller-supplied value" do
    other = create(:user)
    described_class.new(user:, model:, contract_class:).call(params.merge(principal: other))
    expect(model.principal).to eq(user)
  end
end
