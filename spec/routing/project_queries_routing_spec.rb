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

RSpec.describe "Project query routes" do
  it "/project_queries/new GET routes to projects/queries#new" do
    expect(get("/project_queries/new")).to route_to("projects/queries#new")
  end

  it "/project_queries POST routes to projects/queries#create" do
    expect(post("/project_queries")).to route_to("projects/queries#create")
  end

  it "/project_queries/:id DELETE routes to projects/queries#destroy" do
    expect(delete("/project_queries/42")).to route_to("projects/queries#destroy",
                                                      id: "42")
  end

  it "/project_queries/:id/destroy_confirmation_modal GET routes to projects/queries#destroy_confirmation_modal" do
    expect(get("/project_queries/42/destroy_confirmation_modal")).to route_to("projects/queries#destroy_confirmation_modal",
                                                                              id: "42")
  end

  it "/project_queries/:id/configure_view_modal GET routes to projects/queries#configure_view_modal" do
    expect(get("/project_queries/configure_view_modal")).to route_to("projects/queries#configure_view_modal")
  end
end
