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

RSpec.describe "Global resource planners requests", type: :rails_request, with_ee: %i[resource_management] do
  shared_let(:project) { create(:project, name: "Alpha", enabled_module_names: %w[resource_management]) }
  shared_let(:user) { create(:user, member_with_permissions: { project => %i[view_resource_planners] }) }

  before { login_as(user) }

  it "renders the global index with the global sidebar menu" do
    get resource_planners_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("resource_planners_sidemenu")
    expect(response.body).to include(menu_resource_planners_path)
  end

  context "without any resource planner permission" do
    before { login_as(create(:user)) }

    it "is forbidden" do
      get resource_planners_path

      expect(response).to have_http_status(:forbidden)
    end
  end
end
