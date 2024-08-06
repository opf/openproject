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

require File.expand_path("../../../spec_helper", __dir__)

RSpec.describe OpenProject::GithubIntegration::HookHandler do
  describe "#process" do
    let(:handler) { described_class.new }
    let(:hook) { "fake hook" }
    let(:params) { ActionController::Parameters.new({ payload: { "fake" => "value" } }) }
    let(:environment) do
      { "HTTP_X_GITHUB_EVENT" => "pull_request",
        "HTTP_X_GITHUB_DELIVERY" => "veryuniqueid" }
    end
    let(:request) { OpenStruct.new(env: environment) }
    let(:user) do
      user = instance_double(User)
      allow(user).to receive(:id).and_return(12)
      user
    end

    context "with an unsupported event" do
      let(:environment) do
        { "HTTP_X_GITHUB_EVENT" => "X-unspupported",
          "HTTP_X_GITHUB_DELIVERY" => "veryuniqueid2" }
      end

      it "returns 404" do
        result = handler.process(hook, request, params, user)
        expect(result).to eq(404)
      end
    end

    context "with a supported event and without user" do
      let(:user) { nil }

      it "returns 403" do
        result = handler.process(hook, request, params, user)
        expect(result).to eq(403)
      end
    end

    context "with a supported event and a user" do
      let(:expected_params) do
        {
          "fake" => "value",
          "open_project_user_id" => 12,
          "github_event" => "pull_request",
          "github_delivery" => "veryuniqueid"
        }
      end

      before do
        allow(OpenProject::Notifications).to receive(:send)
      end

      it "sends a notification with the correct contents" do
        handler.process(hook, request, params, user)
        expect(OpenProject::Notifications).to have_received(:send).with("github.pull_request", expected_params)
      end

      it "returns 200" do
        result = handler.process(hook, request, params, user)
        expect(result).to eq(200)
      end
    end
  end
end
