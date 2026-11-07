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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe "Work package type projects tab routes" do
  shared_examples "projects tab routes" do |prefix, ids|
    it "removes the type from projects through the link resource" do
      expect(delete: "#{prefix}/projects/link")
        .to route_to("work_package_types/projects_tab/links#destroy", **ids)
    end

    it "confirms that removal through a nested deletion resource" do
      expect(get: "#{prefix}/projects/link/deletion/new")
        .to route_to("work_package_types/projects_tab/links/deletions#new", **ids)
    end

    it "opens a switch through the switch resource" do
      expect(get: "#{prefix}/projects/switch/new")
        .to route_to("work_package_types/projects_tab/switches#new", **ids)
    end

    it "switches through the switch resource" do
      expect(post: "#{prefix}/projects/switch")
        .to route_to("work_package_types/projects_tab/switches#create", **ids)
    end

    it "confirms a switch through a nested confirmation resource" do
      expect(get: "#{prefix}/projects/switch/confirmation/new")
        .to route_to("work_package_types/projects_tab/switches/confirmations#new", **ids)
    end

    it "no longer offers the legacy switch dialog action" do
      expect(get: "#{prefix}/projects/new_switch").not_to be_routable
    end

    it "opens the add dialog through the link resource" do
      expect(get: "#{prefix}/projects/link/new")
        .to route_to("work_package_types/projects_tab/links#new", **ids)
    end

    it "adds projects through the link resource" do
      expect(post: "#{prefix}/projects/link")
        .to route_to("work_package_types/projects_tab/links#create", **ids)
    end

    it "lists the projects that can be linked as nested candidates" do
      expect(get: "#{prefix}/projects/link/candidates")
        .to route_to("work_package_types/projects_tab/links/candidates#index", **ids)
    end

    it "no longer offers the legacy link actions" do
      expect(get: "#{prefix}/projects/new_link").not_to be_routable
      expect(get: "#{prefix}/projects/tree").not_to be_routable
      expect(delete: "#{prefix}/projects/unlink").not_to be_routable
    end
  end

  it_behaves_like "projects tab routes", "/types/1", { type_id: "1" }
  it_behaves_like "projects tab routes", "/types/1/variants/2", { type_id: "1", variant_id: "2" }
end
