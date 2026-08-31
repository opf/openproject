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

require "rails_helper"

RSpec.describe Overviews::OverviewsController do
  describe "routing" do
    it do
      expect(get("/projects/my-project"))
        .to route_to(
          controller: "overviews/overviews", action: "show", project_id: "my-project"
        )
    end

    it do
      expect(get("/projects/my-project/dashboard"))
        .to route_to(
          controller: "overviews/overviews", action: "dashboard", project_id: "my-project"
        )
    end

    it do
      expect(get("/projects/my-project/project_custom_fields_sidebar"))
        .to route_to(
          controller: "overviews/overviews", action: "project_custom_fields_sidebar", project_id: "my-project"
        )
    end

    it do
      expect(get("/projects/my-project/project_life_cycle_sidebar"))
        .to route_to(
          controller: "overviews/overviews",
          action: "project_life_cycle_sidebar",
          project_id: "my-project"
        )
    end
  end

  describe "named routing" do
    it do
      expect(get(project_overview_path("my-project")))
        .to route_to(
          controller: "overviews/overviews", action: "show", project_id: "my-project"
        )
    end

    it do
      expect(get(dashboard_project_overview_path("my-project")))
        .to route_to(
          controller: "overviews/overviews", action: "dashboard", project_id: "my-project"
        )
    end

    it do
      expect(get(project_custom_fields_sidebar_path("my-project")))
        .to route_to(
          controller: "overviews/overviews", action: "project_custom_fields_sidebar", project_id: "my-project"
        )
    end

    it do
      expect(get(project_life_cycle_sidebar_path("my-project")))
        .to route_to(
          controller: "overviews/overviews",
          action: "project_life_cycle_sidebar",
          project_id: "my-project"
        )
    end
  end
end
