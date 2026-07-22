# frozen_string_literal: true

# -- copyright
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
# ++
require "spec_helper"
require "rack/test"

# Drives the API v3 work package index (the hot read path that eager-loads spent time
# through WorkPackageEagerLoadingWrapper#spent_time_subquery) with the collector wired
# in, checking the rendered spentTime is unchanged by the flag.
RSpec.describe "API v3 work package index with shared_user_permissions_cte",
               content_type: :json do
  include API::V3::Utilities::PathHelper

  shared_let(:project) { create(:project, public: false) }
  shared_let(:role) { create(:project_role, permissions: %i[view_work_packages view_time_entries]) }
  shared_let(:user) { create(:user, member_with_roles: { project => role }) }

  shared_let(:work_package) { create(:work_package, project:) }
  shared_let(:child) { create(:work_package, project:, parent: work_package) }
  shared_let(:self_time_entry) { create(:time_entry, entity: work_package, project:, hours: 2.0) }
  shared_let(:child_time_entry) { create(:time_entry, entity: child, project:, hours: 3.0) }

  current_user { user }

  def spent_time_by_id
    get api_v3_paths.work_packages
    expect(last_response).to have_http_status(200)

    JSON.parse(last_response.body)
        .dig("_embedded", "elements")
        .to_h { |element| [element["id"], element["spentTime"]] }
  end

  it "renders the same spent times with the flag on as with it off" do
    with_flags(shared_user_permissions_cte: false)
    legacy = spent_time_by_id

    with_flags(shared_user_permissions_cte: true)
    collapsed = spent_time_by_id

    expect(collapsed).to eq(legacy)
    # Parent rolls up its own and its descendant's entries; child carries only its own.
    expect(legacy[work_package.id]).to eq("PT5H")
    expect(legacy[child.id]).to eq("PT3H")
  end
end
