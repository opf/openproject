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

RSpec.describe Backlogs::SprintsController do
  describe "routing" do
    it {
      expect(get("/projects/project_42/backlogs/sprints/new_dialog")).to route_to(
        controller: "backlogs/sprints",
        action: "new_dialog",
        project_id: "project_42"
      )
    }

    it {
      expect(get("/projects/project_42/backlogs/sprints/refresh_form")).to route_to(
        controller: "backlogs/sprints",
        action: "refresh_form",
        project_id: "project_42"
      )
    }

    it {
      expect(get("/projects/project_42/backlogs/sprints")).to route_to(
        controller: "backlogs/sprints",
        action: "index",
        project_id: "project_42"
      )
    }

    it {
      expect(post("/projects/project_42/backlogs/sprints")).to route_to(
        controller: "backlogs/sprints",
        action: "create",
        project_id: "project_42"
      )
    }

    it {
      expect(get("/projects/project_42/backlogs/sprints/21/edit_dialog")).to route_to(
        controller: "backlogs/sprints",
        action: "edit_dialog",
        project_id: "project_42",
        sprint_id: "21"
      )
    }

    it {
      expect(put("/projects/project_42/backlogs/sprints/21")).to route_to(
        controller: "backlogs/sprints",
        action: "update",
        project_id: "project_42",
        sprint_id: "21"
      )
    }

    it {
      expect(post("/projects/project_42/backlogs/sprints/21/start")).to route_to(
        controller: "backlogs/sprints",
        action: "start",
        project_id: "project_42",
        sprint_id: "21"
      )
    }

    it {
      expect(post("/projects/project_42/backlogs/sprints/21/finish")).to route_to(
        controller: "backlogs/sprints",
        action: "finish",
        project_id: "project_42",
        sprint_id: "21"
      )
    }
  end

  describe "named routing" do
    it {
      expect(new_dialog_project_backlogs_sprints_path("project_42"))
        .to eq("/projects/project_42/backlogs/sprints/new_dialog")
    }

    it {
      expect(project_backlogs_sprints_path("project_42"))
        .to eq("/projects/project_42/backlogs/sprints")
    }

    it {
      expect(project_backlogs_sprint_path("project_42", "21"))
        .to eq("/projects/project_42/backlogs/sprints/21")
    }
  end
end
