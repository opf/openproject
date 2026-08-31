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

RSpec.shared_examples_for "resource planner contract" do
  shared_let(:project) { create(:project, enabled_module_names: %w[resource_management]) }
  shared_let(:owner) { create(:user) }

  let(:public_planner) { false }
  let(:resource_planner) do
    build_stubbed(:resource_planner, project:, principal: owner, public: public_planner)
  end

  context "when user is the owner with view_resource_planners permission" do
    let(:current_user) do
      create(:user, member_with_permissions: { project => %i[view_resource_planners] })
    end
    let(:owner) { current_user }

    it_behaves_like "contract is valid"
  end

  context "when user has manage_public_resource_planners and the planner is public" do
    let(:current_user) do
      create(:user, member_with_permissions: { project => %i[view_resource_planners manage_public_resource_planners] })
    end
    let(:public_planner) { true }

    it_behaves_like "contract is valid"
  end

  context "when user has manage_public_resource_planners but the planner is private" do
    let(:current_user) do
      create(:user, member_with_permissions: { project => %i[view_resource_planners manage_public_resource_planners] })
    end
    let(:public_planner) { false }

    it_behaves_like "contract user is unauthorized"
  end

  context "when user is the owner but lacks view_resource_planners" do
    let(:current_user) { create(:user) }
    let(:owner) { current_user }

    it_behaves_like "contract user is unauthorized"
  end

  context "when user is neither the owner nor has manage permission" do
    let(:current_user) do
      create(:user, member_with_permissions: { project => %i[view_resource_planners] })
    end

    it_behaves_like "contract user is unauthorized"
  end
end
