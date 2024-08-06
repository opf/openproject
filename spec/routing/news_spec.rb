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

RSpec.describe NewsController, "routing" do
  context "project scoped" do
    it {
      expect(subject).to route(:get, "/projects/567/news").to(controller: "news",
                                                              action: "index",
                                                              project_id: "567")
    }

    it do
      expect(get("/projects/567/news.atom"))
        .to route_to(controller: "news",
                     action: "index",
                     format: "atom",
                     project_id: "567")
    end

    it {
      expect(subject).to route(:get, "/projects/567/news/new").to(controller: "news",
                                                                  action: "new",
                                                                  project_id: "567")
    }

    it {
      expect(subject).to route(:post, "/projects/567/news").to(controller: "news",
                                                               action: "create",
                                                               project_id: "567")
    }
  end

  it {
    expect(subject).to route(:get, "/news").to(controller: "news",
                                               action: "index")
  }

  it do
    expect(get("/news.atom"))
      .to route_to(controller: "news",
                   action: "index",
                   format: "atom")
  end

  it {
    expect(subject).to route(:get, "/news/2").to(controller: "news",
                                                 action: "show",
                                                 id: "2")
  }

  it {
    expect(subject).to route(:get, "/news/234").to(controller: "news",
                                                   action: "show",
                                                   id: "234")
  }

  it {
    expect(subject).to route(:get, "/news/567/edit").to(controller: "news",
                                                        action: "edit",
                                                        id: "567")
  }

  it {
    expect(subject).to route(:put, "/news/567").to(controller: "news",
                                                   action: "update",
                                                   id: "567")
  }

  it {
    expect(subject).to route(:delete, "/news/567").to(controller: "news",
                                                      action: "destroy",
                                                      id: "567")
  }
end
