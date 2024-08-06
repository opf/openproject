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

RSpec.describe WatchersController do
  shared_examples_for "watched model routes" do
    before do
      allow(OpenProject::Acts::Watchable::RouteConstraint).to receive(:matches?).and_return(true)
    end

    it "connects POST /:object_type/:object_id/watch to watchers#watch" do
      expect(post("/#{type}/1/watch")).to route_to(controller: "watchers",
                                                   action: "watch",
                                                   object_type: type,
                                                   object_id: "1")
    end

    it "connects DELETE /:object_type/:id/unwatch to watchers#unwatch" do
      expect(delete("/#{type}/1/unwatch")).to route_to(controller: "watchers",
                                                       action: "unwatch",
                                                       object_type: type,
                                                       object_id: "1")
    end
  end

  ["issues", "news", "boards", "messages", "wikis", "wiki_pages"].each do |type|
    describe "routing #{type} watches" do
      let(:type) { type }

      it_behaves_like "watched model routes"
    end
  end
end
