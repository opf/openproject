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

RSpec.describe "types routes" do
  it do
    expect(post("/types/move/123")).to route_to(controller: "work_package_types/types",
                                                action: "move",
                                                id: "123")
  end

  describe "workflow tab (mounted on the type edit page)" do
    it do
      expect(get("/types/42/workflow/edit"))
        .to route_to("work_package_types/workflow_tab#edit", type_id: "42")
    end

    it do
      expect(get("/types/42/workflow/matrix"))
        .to route_to("workflows/matrix#show", type_id: "42")
    end

    it do
      expect(patch("/types/42/workflow/matrix"))
        .to route_to("workflows/matrix#update", type_id: "42")
    end

    it do
      expect(get("/types/42/workflow/matrix/status_dialog"))
        .to route_to("workflows/matrix#status_dialog", type_id: "42")
    end

    it do
      expect(post("/types/42/workflow/matrix/confirm_statuses"))
        .to route_to("workflows/matrix#confirm_statuses", type_id: "42")
    end

    it "carries the transition tab as a query param rather than a path segment" do
      expect(get("/types/42/workflow/matrix?tab=author"))
        .to route_to("workflows/matrix#show", type_id: "42", tab: "author")
    end
  end

  describe "workflow copy (nested under the type)" do
    it do
      expect(get("/types/42/workflow/copy/new"))
        .to route_to("workflows/copies#new", type_id: "42")
    end

    it do
      expect(post("/types/42/workflow/copy/from_variant"))
        .to route_to("workflows/copies/from_variants#create", type_id: "42")
    end

    it do
      expect(post("/types/42/workflow/copy/from_role"))
        .to route_to("workflows/copies/from_roles#create", type_id: "42")
    end
  end

  describe "workflow summary (types collection action)" do
    it do
      expect(get("/types/workflow_summary"))
        .to route_to("workflows/summaries#show")
    end
  end
end
