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

RSpec.describe MessagesController, "routing" do
  context "project scoped" do
    it {
      expect(subject).to route(:get, "/forums/lala/topics/new").to(controller: "messages",
                                                                   action: "new",
                                                                   forum_id: "lala")
    }

    it {
      expect(subject).to route(:post, "/forums/lala/topics").to(controller: "messages",
                                                                action: "create",
                                                                forum_id: "lala")
    }
  end

  it {
    expect(subject).to route(:get, "/topics/2").to(controller: "messages",
                                                   action: "show",
                                                   id: "2")
  }

  it {
    expect(subject).to route(:get, "/topics/22/edit").to(controller: "messages",
                                                         action: "edit",
                                                         id: "22")
  }

  it {
    expect(subject).to route(:put, "/topics/22").to(controller: "messages",
                                                    action: "update",
                                                    id: "22")
  }

  it {
    expect(subject).to route(:delete, "/topics/555").to(controller: "messages",
                                                        action: "destroy",
                                                        id: "555")
  }

  it {
    expect(subject).to route(:get, "/topics/22/quote").to(controller: "messages",
                                                          action: "quote",
                                                          id: "22")
  }

  it {
    expect(subject).to route(:post, "/topics/555/reply").to(controller: "messages",
                                                            action: "reply",
                                                            id: "555")
  }
end
