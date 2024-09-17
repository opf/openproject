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

RSpec.describe ProjectsController do
  describe "index" do
    it do
      expect(get("/projects")).to route_to(
        controller: "projects", action: "index"
      )
    end

    it do
      expect(get("/projects.csv")).to route_to(
        controller: "projects", action: "index", format: "csv"
      )
    end

    it do
      expect(get("/projects.xls")).to route_to(
        controller: "projects", action: "index", format: "xls"
      )
    end
  end

  describe "new" do
    it do
      expect(get("/projects/new")).to route_to(
        controller: "projects", action: "new"
      )
    end
  end

  describe "destroy_info" do
    it do
      expect(get("/projects/123/destroy_info")).to route_to(
        controller: "projects", action: "destroy_info", id: "123"
      )
    end
  end

  describe "delete" do
    it do
      expect(delete("/projects/123")).to route_to(
        controller: "projects", action: "destroy", id: "123"
      )
    end

    it do
      expect(delete("/projects/123.xml")).to route_to(
        controller: "projects", action: "destroy", id: "123", format: "xml"
      )
    end
  end

  describe "export_list_modal" do
    it do
      expect(get("/projects/export_list_modal")).to route_to(
        controller: "projects", action: "export_list_modal"
      )
    end
  end

  describe "templated" do
    it do
      expect(delete("/projects/123/templated"))
        .to route_to(controller: "projects/templated", action: "destroy", project_id: "123")
    end

    it do
      expect(post("/projects/123/templated"))
        .to route_to(controller: "projects/templated", action: "create", project_id: "123")
    end
  end

  describe "miscellaneous" do
    it do
      expect(post("projects/123/archive")).to route_to(
        controller: "projects/archive", action: "create", project_id: "123"
      )
    end

    it do
      expect(delete("projects/123/archive")).to route_to(
        controller: "projects/archive", action: "destroy", project_id: "123"
      )
    end

    it do
      expect(get("projects/123/copy")).to route_to(
        controller: "projects", action: "copy", id: "123"
      )
    end
  end

  describe "types" do
    it do
      expect(patch("/projects/123/types")).to route_to(
        controller: "projects", action: "types", id: "123"
      )
    end
  end
end
