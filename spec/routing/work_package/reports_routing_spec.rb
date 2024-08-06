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

RSpec.describe WorkPackagesController do
  it "connects GET /project/1/work_packages/report to work_package/report#report" do
    expect(get("/projects/1/work_packages/report")).to route_to(controller: "work_packages/reports",
                                                                action: "report",
                                                                project_id: "1")
  end

  it "connects GET /project/1/work_packages/report/assigned_to to work_package/report#report_details" do
    expect(get("/projects/1/work_packages/report/assigned_to")).to route_to(controller: "work_packages/reports",
                                                                            action: "report_details",
                                                                            project_id: "1",
                                                                            detail: "assigned_to")
  end
end
