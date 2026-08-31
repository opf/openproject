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

RSpec.describe Backlogs::BacklogController do
  describe "routing" do
    it {
      route = "/projects/project_42/backlogs/backlog"
      expect(get(route)).to route_to(controller: "backlogs/backlog",
                                     action: "show",
                                     project_id: "project_42")
    }

    it {
      expect(get("/projects/project_42/backlogs/backlog/details/33")).to route_to(
        controller: "backlogs/backlog",
        action: "details",
        project_id: "project_42",
        work_package_id: "33",
        tab: :overview,
        work_package_split_view: true
      )
    }
  end

  describe "named routing" do
    it {
      # TODO: This is a legacy redirect route that needs to be removed in 18.0
      expect(project_backlogs_path("project_42")).to eq("/projects/project_42/backlogs")
    }

    it {
      expect(project_backlogs_backlog_path("project_42")).to eq("/projects/project_42/backlogs/backlog")
    }

    it {
      expect(project_backlogs_backlog_details_path("project_42", "33"))
        .to eq("/projects/project_42/backlogs/backlog/details/33")
    }
  end
end
