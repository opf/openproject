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

RSpec.describe "Gantt routing" do
  context "with :project_id" do
    it "routes to gantt#index" do
      expect(subject)
        .to route(:get, "/projects/foobar/gantt")
              .to(controller: "gantt/gantt", action: :index, project_id: "foobar")
    end

    it "connects GET /projects/:project_id/gantt/create_new to gantt#index" do
      expect(get("/projects/1/gantt/create_new"))
        .to route_to(controller: "gantt/gantt",
                     action: "index",
                     project_id: "1",
                     state: "create_new")
    end

    it "connects GET /projects/:project_id/gantt/details/:id/:state to gantt#index" do
      expect(get("/projects/1/gantt/details/2/overview"))
        .to route_to(controller: "gantt/gantt",
                     action: "index",
                     project_id: "1",
                     state: "details/2/overview")
    end
  end

  context "without :project_id" do
    it "routes to gantt#index" do
      expect(subject)
        .to route(:get, "/gantt")
              .to(controller: "gantt/gantt", action: :index)
    end

    it "connects GET /gantt/details/:state to gantt#index" do
      expect(get("/gantt/details/5/overview"))
        .to route_to(controller: "gantt/gantt",
                     action: "index",
                     state: "5/overview")
    end
  end
end
