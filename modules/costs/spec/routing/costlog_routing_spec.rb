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

RSpec.describe CostlogController do
  describe "routing" do
    it {
      expect(get("/projects/blubs/cost_entries/new")).to route_to(controller: "costlog",
                                                                  action: "new",
                                                                  project_id: "blubs")
    }

    it {
      expect(post("/projects/blubs/cost_entries")).to route_to(controller: "costlog",
                                                               action: "create",
                                                               project_id: "blubs")
    }

    it {
      expect(get("/work_packages/5/cost_entries/new")).to route_to(controller: "costlog",
                                                                   action: "new",
                                                                   work_package_id: "5")
    }

    it {
      expect(get("/cost_entries/5/edit")).to route_to(controller: "costlog",
                                                      action: "edit",
                                                      id: "5")
    }

    it {
      expect(put("/cost_entries/5")).to route_to(controller: "costlog",
                                                 action: "update",
                                                 id: "5")
    }

    it {
      expect(delete("/cost_entries/5")).to route_to(controller: "costlog",
                                                    action: "destroy",
                                                    id: "5")
    }
  end
end
