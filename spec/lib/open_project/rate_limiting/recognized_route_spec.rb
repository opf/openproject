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

RSpec.describe OpenProject::RateLimiting::RecognizedRoute do
  def request_for(path, method: "POST", path_parameters: nil)
    env = Rack::MockRequest.env_for(path, method:)
    env[ActionDispatch::Http::Parameters::PARAMETERS_KEY] = path_parameters if path_parameters
    Rack::Attack::Request.new(env)
  end

  describe ".fetch" do
    it "recognizes the route" do
      route = described_class.fetch(request_for("/account/register"))

      expect(route).to include(controller: "account", action: "register")
    end

    it "returns nil for an unknown path" do
      expect(described_class.fetch(request_for("/this/does/not/exist"))).to be_nil
    end

    it "memoizes recognition on the request env" do
      req = request_for("/account/register")
      allow(OpenProject::StaticRouting).to receive(:recognize_route).and_call_original

      2.times { described_class.fetch(req) }

      expect(OpenProject::StaticRouting).to have_received(:recognize_route).once
    end

    it "memoizes a miss so unknown paths are not recognized twice" do
      req = request_for("/this/does/not/exist")
      allow(OpenProject::StaticRouting).to receive(:recognize_route).and_call_original

      2.times { described_class.fetch(req) }

      expect(OpenProject::StaticRouting).to have_received(:recognize_route).once
    end

    it "uses path_parameters when the router has already run" do
      req = request_for(
        "/ignored",
        path_parameters: { controller: "account", action: "register" }
      )
      allow(OpenProject::StaticRouting).to receive(:recognize_route)

      expect(described_class.fetch(req)).to include(controller: "account", action: "register")
      expect(OpenProject::StaticRouting).not_to have_received(:recognize_route)
    end
  end

  describe ".matches?" do
    it "is true for the given controller and action" do
      expect(described_class).to be_matches(request_for("/account/register"),
                                            controller: "account",
                                            action: "register")
    end

    it "is false for a different action" do
      expect(described_class).not_to be_matches(request_for("/account/lost_password"),
                                                controller: "account",
                                                action: "register")
    end
  end
end
