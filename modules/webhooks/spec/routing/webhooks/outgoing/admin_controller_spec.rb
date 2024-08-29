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

RSpec.describe "Outgoing webhooks administration" do
  it "route to index" do
    expect(get("/admin/settings/webhooks")).to route_to("webhooks/outgoing/admin#index")
  end

  it "route to new" do
    expect(get("/admin/settings/webhooks/new")).to route_to("webhooks/outgoing/admin#new")
  end

  it "route to show" do
    expect(get("/admin/settings/webhooks/1")).to route_to(controller: "webhooks/outgoing/admin",
                                                          action: "show",
                                                          webhook_id: "1")
  end

  it "route to edit" do
    expect(get("/admin/settings/webhooks/1/edit")).to route_to(controller: "webhooks/outgoing/admin",
                                                               action: "edit",
                                                               webhook_id: "1")
  end

  it "route to PUT update" do
    expect(put("/admin/settings/webhooks/1")).to route_to(controller: "webhooks/outgoing/admin",
                                                          action: "update",
                                                          webhook_id: "1")
  end

  it "route to DELETE destroy" do
    expect(delete("/admin/settings/webhooks/1")).to route_to(controller: "webhooks/outgoing/admin",
                                                             action: "destroy",
                                                             webhook_id: "1")
  end
end
