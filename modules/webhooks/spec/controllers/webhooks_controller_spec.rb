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

require File.expand_path("../spec_helper", __dir__)

RSpec.describe Webhooks::Incoming::HooksController do
  let(:hook) { double(OpenProject::Webhooks::Hook) }
  let(:user) { double(User).as_null_object }

  describe "#handle_hook" do
    before do
      expect(OpenProject::Webhooks).to receive(:find).with("testhook").and_return(hook)
      allow(controller).to receive(:find_current_user).and_return(user)
    end

    after do
      # ApplicationController before filter user_setup sets a user
      User.current = nil
    end

    it "is successful" do
      expect(hook).to receive(:handle)

      post :handle_hook, params: { hook_name: "testhook" }

      expect(response).to be_successful
    end

    it "calls the hook with a user" do
      expect(hook).to receive(:handle) { |_env, _params, user|
        expect(user).to equal(user)
      }

      post :handle_hook, params: { hook_name: "testhook" }
    end
  end
end
