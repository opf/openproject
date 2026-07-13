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

RSpec.describe "workflows routes" do
  it { expect(get("/workflows")).to route_to("workflows#index") }

  it { expect(get("/workflows/42/edit")).to route_to("workflows#edit", type_id: "42") }

  it { expect(get("/workflows/42/tabs/always/edit")).to route_to("workflows/tabs#edit", workflow_type_id: "42", tab: "always") }
  it { expect(patch("/workflows/42/tabs/always")).to route_to("workflows/tabs#update", workflow_type_id: "42", tab: "always") }

  it { expect(get("/workflows/42/copy/new")).to route_to("workflows/copies#new", workflow_type_id: "42") }

  it do
    expect(get("/workflows/42/copy/new?source_role_id=23"))
    .to route_to("workflows/copies#new", workflow_type_id: "42", source_role_id: "23")
  end

  it { expect(post("/workflows/42/copy/from_type")).to route_to("workflows/copies/from_types#create", workflow_type_id: "42") }
  it { expect(post("/workflows/42/copy/from_role")).to route_to("workflows/copies/from_roles#create", workflow_type_id: "42") }

  it { expect(get("/workflows/summary")).to route_to("workflows/summaries#show") }
end
