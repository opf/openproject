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

RSpec.describe "work package share routes" do
  it "connects GET /work_packages/:wp_id/shares to shares#index" do
    expect(get("/work_packages/1/shares")).to route_to(controller: "shares",
                                                       action: "index",
                                                       work_package_id: "1")
  end

  it "connects POST /work_packages/:wp_id/shares to shares#create" do
    expect(post("/work_packages/1/shares")).to route_to(controller: "shares",
                                                        action: "create",
                                                        work_package_id: "1")
  end

  it "connects DELETE /work_packages/:wp_id/shares/:id to shares#delete" do
    expect(delete("/work_packages/1/shares/5")).to route_to(controller: "shares",
                                                            action: "destroy",
                                                            id: "5",
                                                            work_package_id: "1")
  end

  it "connects PATCH /work_packages/:wp_id/shares/:id to shares#update" do
    expect(patch("/work_packages/1/shares/5")).to route_to(controller: "shares",
                                                           action: "update",
                                                           id: "5",
                                                           work_package_id: "1")
  end

  it "connects PUT /work_packages/:wp_id/shares/:id to shares#update" do
    expect(put("/work_packages/1/shares/5")).to route_to(controller: "shares",
                                                         action: "update",
                                                         id: "5",
                                                         work_package_id: "1")
  end

  it "connects POST /work_packages/:wp_id/shares/:id/resend_invite to shares#resend_invite" do
    expect(post("/work_packages/1/shares/5/resend_invite")).to route_to(controller: "shares",
                                                                        action: "resend_invite",
                                                                        id: "5",
                                                                        work_package_id: "1")
  end

  context "on bulk actions" do
    it "routes DELETE /work_packages/:work_package_id/shares/bulk to shares/bulk#destroy" do
      expect(delete("/work_packages/1/shares/bulk"))
        .to route_to(controller: "shares",
                     action: "bulk_destroy",
                     work_package_id: "1")
    end

    it "routes PATCH /work_packages/:work_package_id/shares/bulk to shares/bulk#update" do
      expect(patch("/work_packages/1/shares/bulk"))
        .to route_to(controller: "shares",
                     action: "bulk_update",
                     work_package_id: "1")
    end
  end
end
