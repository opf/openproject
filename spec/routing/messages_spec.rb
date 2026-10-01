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

RSpec.describe MessagesController, "routing" do
  context "with projects scoped forums" do
    it do
      expect(subject).to route(:get, "/projects/some-project/forums/lala/topics/new").to(controller: "messages",
                                                                                         action: "new",
                                                                                         project_id: "some-project",
                                                                                         forum_id: "lala")
    end

    it do
      expect(subject).to route(:post, "/projects/some-project/forums/lala/topics").to(controller: "messages",
                                                                                      action: "create",
                                                                                      project_id: "some-project",
                                                                                      forum_id: "lala")
    end
  end

  it do
    expect(subject).to route(:get, "/projects/some-project/forums/lala/topics/2").to(controller: "messages",
                                                                                     action: "show",
                                                                                     project_id: "some-project",
                                                                                     forum_id: "lala",
                                                                                     id: "2")
  end

  it do
    expect(subject).to route(:get, "/projects/some-project/forums/lala/topics/22/edit").to(controller: "messages",
                                                                                           action: "edit",
                                                                                           project_id: "some-project",
                                                                                           forum_id: "lala",
                                                                                           id: "22")
  end

  it do
    expect(subject).to route(:put, "/projects/some-project/forums/lala/topics/22").to(controller: "messages",
                                                                                      action: "update",
                                                                                      project_id: "some-project",
                                                                                      forum_id: "lala",
                                                                                      id: "22")
  end

  it do
    expect(subject).to route(:delete, "/projects/some-project/forums/lala/topics/555").to(controller: "messages",
                                                                                          action: "destroy",
                                                                                          project_id: "some-project",
                                                                                          forum_id: "lala",
                                                                                          id: "555")
  end

  it do
    expect(subject).to route(:get, "/projects/some-project/forums/lala/topics/22/quote").to(controller: "messages",
                                                                                            action: "quote",
                                                                                            project_id: "some-project",
                                                                                            forum_id: "lala",
                                                                                            id: "22")
  end

  it do
    expect(subject).to route(:post, "/projects/some-project/forums/lala/topics/555/reply").to(controller: "messages",
                                                                                              action: "reply",
                                                                                              project_id: "some-project",
                                                                                              forum_id: "lala",
                                                                                              id: "555")
  end
end
