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

RSpec.describe "custom_actions routes" do
  describe "index" do
    it "links GET /admin/custom_actions" do
      expect(get("/admin/custom_actions"))
        .to route_to("custom_actions#index")
    end
  end

  describe "new" do
    it "links GET /admin/custom_actions/new" do
      expect(get("/admin/custom_actions/new"))
        .to route_to("custom_actions#new")
    end
  end

  describe "create" do
    it "links POST /admin/custom_actions" do
      expect(post("/admin/custom_actions"))
        .to route_to("custom_actions#create")
    end
  end

  describe "edit" do
    it "links GET /admin/custom_actions/:id/edit" do
      expect(get("/admin/custom_actions/42/edit"))
        .to route_to("custom_actions#edit", id: "42")
    end
  end

  describe "update" do
    it "links PATCH /admin/custom_actions/:id" do
      expect(patch("/admin/custom_actions/42"))
        .to route_to("custom_actions#update", id: "42")
    end
  end

  describe "delete" do
    it "links DELETE /admin/custom_actions/:id" do
      expect(delete("/admin/custom_actions/42"))
        .to route_to("custom_actions#destroy", id: "42")
    end
  end
end
