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

RSpec.describe "Team planner routing" do
  it "routes to team_planner#overview" do
    expect(subject)
      .to route(:get, "/team_planners")
            .to(controller: "team_planner/team_planner", action: :overview)
  end

  it "routes to team_planner#index" do
    expect(subject)
      .to route(:get, "/projects/foobar/team_planners")
            .to(controller: "team_planner/team_planner", action: :index, project_id: "foobar")
  end

  it "routes to team_planner#show" do
    expect(subject)
      .to route(:get, "/projects/foobar/team_planners/1234")
            .to(controller: "team_planner/team_planner", action: :show, project_id: "foobar", id: "1234")
  end

  context "with :project_id" do
    it "routes to team_planner#upsale" do
      expect(subject)
        .to route(:get, "/projects/foobar/team_planners/upsale")
              .to(controller: "team_planner/team_planner", action: :upsale, project_id: "foobar")
    end

    it "routes to team_planner#show" do
      expect(subject)
        .to route(:get, "/projects/foobar/team_planners/new")
              .to(controller: "team_planner/team_planner", action: :show, project_id: "foobar")
    end
  end

  context "without :project_id" do
    it "routes to team_planner#upsale" do
      expect(subject)
        .to route(:get, "/team_planners/upsale")
              .to(controller: "team_planner/team_planner", action: :upsale)
    end

    it "routes to team_planner#new" do
      expect(subject)
        .to route(:get, "/team_planners/new")
              .to(controller: "team_planner/team_planner", action: :new)
    end
  end

  it "routes to team_planner#create" do
    expect(subject)
      .to route(:post, "/team_planners")
            .to(controller: "team_planner/team_planner", action: :create)
  end

  it "routes to team_planner#show with state" do
    expect(subject)
      .to route(:get, "/projects/foobar/team_planners/1234/details/555")
            .to(controller: "team_planner/team_planner", action: :show, project_id: "foobar", id: "1234",
                state: "details/555")
  end

  it "routes to team_planner#destroy" do
    expect(subject)
      .to route(:delete, "/projects/foobar/team_planners/1234")
            .to(controller: "team_planner/team_planner", action: :destroy, project_id: "foobar", id: "1234")
  end
end
