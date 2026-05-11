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

RSpec.describe "automations routes" do
  describe "index" do
    it "links GET /admin/automations" do
      expect(get("/admin/automations"))
        .to route_to("automations#index")
    end
  end

  describe "new" do
    it "links GET /admin/automations/new" do
      expect(get("/admin/automations/new"))
        .to route_to("automations#new")
    end
  end

  describe "create" do
    it "links POST /admin/automations" do
      expect(post("/admin/automations"))
        .to route_to("automations#create")
    end
  end

  describe "edit" do
    it "links GET /admin/automations/:id/edit" do
      expect(get("/admin/automations/42/edit"))
        .to route_to("automations#edit", id: "42")
    end
  end

  describe "update" do
    it "links PATCH /admin/automations/:id" do
      expect(patch("/admin/automations/42"))
        .to route_to("automations#update", id: "42")
    end
  end

  describe "delete" do
    it "links DELETE /admin/automations/:id" do
      expect(delete("/admin/automations/42"))
        .to route_to("automations#destroy", id: "42")
    end
  end
end
