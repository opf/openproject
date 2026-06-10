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
require "contracts/shared/model_contract_shared_context"

RSpec.describe ResourcePlannerViews::CreateContract do
  include_context "ModelContract shared context"

  shared_let(:project) { create(:project, enabled_module_names: %w[resource_management]) }
  shared_let(:owner) { create(:user, member_with_permissions: { project => %i[view_resource_planners] }) }

  let(:resource_planner) { build_stubbed(:resource_planner, project:, principal: owner) }
  let(:parent) { resource_planner }
  let(:view) { build_stubbed(:resource_work_package_list, parent:, project:, principal: owner) }
  let(:contract) { described_class.new(view, current_user) }

  context "when the user owns the parent planner" do
    let(:current_user) { owner }

    it_behaves_like "contract is valid"
  end

  context "when the user does not own the parent planner" do
    let(:current_user) do
      create(:user, member_with_permissions: { project => %i[view_resource_planners] })
    end

    it_behaves_like "contract user is unauthorized"
  end

  context "when the parent is not a resource planner" do
    let(:current_user) { owner }
    let(:parent) { build_stubbed(:resource_work_package_list, project:, principal: owner) }

    it "is invalid" do
      expect(contract.validate).to be(false)
      expect(contract.errors).to be_added(:parent, :blank)
    end
  end
end
