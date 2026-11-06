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

require_relative "../spec_helper"

RSpec.describe CostlogController, "update authorization for own-entry permissions" do
  include Cost::PluginSpecHelper

  let(:project) { create(:project_with_types) }
  let(:victim) { create(:user) }
  let(:acting_user) { create(:user) }
  let(:work_package) do
    create(:work_package, project:, author: victim, type: project.enabled_types.first)
  end
  let(:cost_type) { create(:cost_type) }
  let!(:cost_entry) do
    create(:cost_entry,
           entity: work_package,
           project:,
           user: victim,
           cost_type:,
           units: 10,
           spent_on: Date.current)
  end

  before do
    is_member(project, acting_user, %i[view_project view_work_packages view_cost_entries edit_own_cost_entries])
    allow(User).to receive(:current).and_return(acting_user)
    allow(controller).to receive(:check_if_login_required)
    allow(controller.flash).to receive(:sweep)
  end

  after do
    User.current = nil
  end

  describe "PUT update" do
    let(:params) do
      {
        id: cost_entry.id.to_s,
        cost_entry: {
          user_id: acting_user.id.to_s,
          entity_type: "WorkPackage",
          entity_id: work_package.id.to_s,
          cost_type_id: cost_type.id.to_s,
          units: "99",
          spent_on: cost_entry.spent_on.to_s,
          comments: "reassigned through own-entry permission"
        }
      }
    end

    it "rejects reassignment of another user's entry to the acting user" do
      put :update, params: params

      expect(response).to have_http_status(:forbidden)
      expect(cost_entry.reload.user).to eq(victim)
      expect(cost_entry.units).to eq(10)
    end
  end
end
