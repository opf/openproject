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

RSpec.describe Calendar::CalendarsController do
  it do
    expect(get("calendars")).to route_to(controller: "calendar/calendars",
                                         action: "index")
  end

  it do
    expect(get("/projects/1/calendars")).to route_to(controller: "calendar/calendars",
                                                     action: "index",
                                                     project_id: "1")
  end

  it do
    expect(get("/projects/1/calendars/2")).to route_to(controller: "calendar/calendars",
                                                       action: "show",
                                                       id: "2",
                                                       project_id: "1")
  end

  it do
    expect(get("/calendars/new")).to route_to(controller: "calendar/calendars",
                                              action: "new")
  end

  it do
    expect(post("/calendars")).to route_to(controller: "calendar/calendars",
                                           action: "create")
  end

  it do
    expect(delete("/projects/1/calendars/2")).to route_to(controller: "calendar/calendars",
                                                          action: "destroy",
                                                          id: "2",
                                                          project_id: "1")
  end
end
