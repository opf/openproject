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

RSpec.describe ActivitiesController, "routing" do
  it {
    expect(get("/activity")).to route_to(controller: "activities",
                                         action: "index")
  }

  it {
    expect(get("/activity.atom")).to route_to(controller: "activities",
                                              action: "index",
                                              format: "atom")
  }

  it {
    expect(get("/activity/menu")).to route_to(controller: "activities",
                                              action: "menu")
  }

  context "project scoped" do
    it {
      expect(get("/projects/abc/activity")).to route_to(controller: "activities",
                                                        action: "index",
                                                        project_id: "abc")
    }

    it {
      expect(get("/projects/abc/activity.atom")).to route_to(controller: "activities",
                                                             action: "index",
                                                             project_id: "abc",
                                                             format: "atom")
    }

    it {
      expect(get("/projects/abc/activity/menu")).to route_to(controller: "activities",
                                                             action: "menu",
                                                             project_id: "abc")
    }
  end
end
