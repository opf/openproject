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

RSpec.describe "groups routes" do
  it {
    expect(subject).to route(:get, "/admin/groups").to(controller: "groups",
                                                       action: "index")
  }

  it {
    expect(subject).to route(:get, "/admin/groups/new").to(controller: "groups",
                                                           action: "new")
  }

  it {
    expect(subject).to route(:post, "/admin/groups").to(controller: "groups",
                                                        action: "create")
  }

  it {
    expect(subject).to route(:get, "/groups/4").to(controller: "groups",
                                                   action: "show",
                                                   id: "4")
  }

  it {
    expect(subject).to route(:get, "/admin/groups/4/edit").to(controller: "groups",
                                                              action: "edit",
                                                              id: "4")
  }

  it {
    expect(subject).to route(:put, "/admin/groups/4").to(controller: "groups",
                                                         action: "update",
                                                         id: "4")
  }

  it {
    expect(subject).to route(:delete, "/admin/groups/4").to(controller: "groups",
                                                            action: "destroy",
                                                            id: "4")
  }

  it {
    expect(subject).to route(:post, "/admin/groups/4/members").to(controller: "groups",
                                                                  action: "add_users",
                                                                  id: "4")
  }

  it {
    expect(subject).to route(:delete, "/admin/groups/4/members/5").to(controller: "groups",
                                                                      action: "remove_user",
                                                                      id: "4",
                                                                      user_id: "5")
  }

  it {
    expect(subject).to route(:post, "/admin/groups/4/memberships").to(controller: "groups",
                                                                      action: "create_memberships",
                                                                      id: "4")
  }

  it {
    expect(subject).to route(:put, "/admin/groups/4/memberships/5").to(controller: "groups",
                                                                       action: "edit_membership",
                                                                       id: "4",
                                                                       membership_id: "5")
  }

  it {
    expect(subject).to route(:delete, "/admin/groups/4/memberships/5").to(controller: "groups",
                                                                          action: "destroy_membership",
                                                                          id: "4",
                                                                          membership_id: "5")
  }
end
