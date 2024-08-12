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

RSpec.describe MembersController do
  describe "project scoped" do
    it {
      expect(subject).to route(:post, "/projects/5234/members").to(controller: "members",
                                                                   action: "create",
                                                                   project_id: "5234")
    }

    it {
      expect(subject).to route(:get, "/projects/5234/members/autocomplete_for_member")
                       .to(controller: "members",
                           action: "autocomplete_for_member",
                           project_id: "5234")
    }
  end

  it {
    expect(subject).to route(:put, "/members/5234").to(controller: "members",
                                                       action: "update",
                                                       id: "5234")
  }

  it {
    expect(subject).to route(:delete, "/projects/5234/members/by_principal/8158").to(controller: "members",
                                                                                     action: "destroy_by_principal",
                                                                                     project_id: "5234",
                                                                                     principal_id: "8158")
  }
end
