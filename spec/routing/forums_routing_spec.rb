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

RSpec.describe ForumsController do
  it {
    expect(subject).to route(:get, "/projects/world_domination/forums").to(controller: "forums",
                                                                           action: "index",
                                                                           project_id: "world_domination")
  }

  it {
    expect(subject).to route(:get, "/projects/world_domination/forums/new").to(controller: "forums",
                                                                               action: "new",
                                                                               project_id: "world_domination")
  }

  it {
    expect(subject).to route(:post, "/projects/world_domination/forums").to(controller: "forums",
                                                                            action: "create",
                                                                            project_id: "world_domination")
  }

  it {
    expect(subject).to route(:get, "/projects/world_domination/forums/44").to(controller: "forums",
                                                                              action: "show",
                                                                              project_id: "world_domination",
                                                                              id: "44")
  }

  it {
    expect(get("/projects/abc/forums/1.atom"))
      .to route_to(controller: "forums",
                   action: "show",
                   project_id: "abc",
                   id: "1",
                   format: "atom")
  }

  it {
    expect(subject).to route(:get, "/projects/world_domination/forums/44/edit").to(controller: "forums",
                                                                                   action: "edit",
                                                                                   project_id: "world_domination",
                                                                                   id: "44")
  }

  it {
    expect(subject).to route(:put, "/projects/world_domination/forums/44").to(controller: "forums",
                                                                              action: "update",
                                                                              project_id: "world_domination",
                                                                              id: "44")
  }

  it {
    expect(subject).to route(:delete, "/projects/world_domination/forums/44").to(controller: "forums",
                                                                                 action: "destroy",
                                                                                 project_id: "world_domination",
                                                                                 id: "44")
  }

  it "connects GET /projects/:project/forums/:forum/move to forums#move" do
    expect(get("/projects/1/forums/1/move")).to route_to(controller: "forums",
                                                         action: "move",
                                                         project_id: "1",
                                                         id: "1")
  end

  it "connects POST /projects/:project/forums/:forum/move to forums#move" do
    expect(post("/projects/1/forums/1/move")).to route_to(controller: "forums",
                                                          action: "move",
                                                          project_id: "1",
                                                          id: "1")
  end
end
