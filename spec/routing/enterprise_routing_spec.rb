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

RSpec.describe EnterprisesController do
  context "when `ee_manager_visible`" do
    it "connects GET /admin/enterprise to enterprises#show" do
      allow(OpenProject::Configuration).to receive(:ee_manager_visible?).and_return(true)
      expect(get("/admin/enterprise")).to route_to(controller: "enterprises",
                                                   action: "show")
    end
  end

  context "when NOT `ee_manager_visible`" do
    it "GET /admin/enterprise should not route to enterprise#show" do
      # With such a configuration and in case a token is present, the might be a
      # good reason not to reveal the enterpise token to the admin.
      # Think of cloud solutions for instance.
      allow(OpenProject::Configuration).to receive(:ee_manager_visible?).and_return(false)
      expect(get("/admin/enterprise")).not_to route_to(controller: "enterprises",
                                                       action: "show")
    end
  end
end
