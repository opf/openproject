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

require_relative "../../../spec_helper"

RSpec.describe OpenProject::GitlabIntegration::HookHandler do
  describe "#process" do
    let(:handler) { described_class.new }
    let(:hook) { "fake hook" }
    let(:params) { ActionController::Parameters.new({ payload: { "fake" => "value" } }) }
    let(:environment) do
      { "HTTP_X_GITLAB_EVENT" => "Merge Request Hook" }
    end
    let(:request) { Struct.new(:env).new(env: environment) }
    let(:user) do
      user = instance_double(User)
      allow(user).to receive(:id).and_return(12)
      user
    end

    context "with an unsupported event" do
      let(:environment) do
        { "HTTP_X_GITLAB_EVENT" => "Unsupported Hook" }
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

    context "with webhook secret verification" do
      let(:secret) { "super_secret" }

      before { allow(OpenProject::Notifications).to receive(:send) }

      context "when a secret is configured and the token matches",
              with_settings: { plugin_openproject_gitlab_integration: { webhook_secret: "super_secret" } } do
        let(:environment) do
          { "HTTP_X_GITLAB_EVENT" => "Merge Request Hook",
            "HTTP_X_GITLAB_TOKEN" => secret }
        end

        it "returns 200" do
          expect(handler.process(hook, request, params, user)).to eq(200)
        end
      end

      context "when a secret is configured and the token is wrong",
              with_settings: { plugin_openproject_gitlab_integration: { webhook_secret: "super_secret" } } do
        let(:environment) do
          { "HTTP_X_GITLAB_EVENT" => "Merge Request Hook",
            "HTTP_X_GITLAB_TOKEN" => "wrong_secret" }
        end

        it "returns 403" do
          expect(handler.process(hook, request, params, user)).to eq(403)
        end

        it "does not send a notification" do
          handler.process(hook, request, params, user)
          expect(OpenProject::Notifications).not_to have_received(:send)
        end
      end

      context "when a secret is configured and the token header is missing",
              with_settings: { plugin_openproject_gitlab_integration: { webhook_secret: "super_secret" } } do
        it "returns 403" do
          expect(handler.process(hook, request, params, user)).to eq(403)
        end

        it "does not send a notification" do
          handler.process(hook, request, params, user)
          expect(OpenProject::Notifications).not_to have_received(:send)
        end
      end

      context "when no secret is configured",
              with_settings: { plugin_openproject_gitlab_integration: {} } do
        it "returns 200 without requiring a token" do
          expect(handler.process(hook, request, params, user)).to eq(200)
        end
      end
    end

    context "with a supported event and a user" do
      let(:expected_params) do
        {
          "fake" => "value",
          "open_project_user_id" => 12,
          "gitlab_event" => "merge_request_hook"
        }
      end

      before do
        allow(OpenProject::Notifications).to receive(:send)
      end

      it "sends a notification with the correct contents" do
        handler.process(hook, request, params, user)
        expect(OpenProject::Notifications).to have_received(:send).with(:"gitlab.merge_request_hook", expected_params)
      end

      it "returns 200" do
        result = handler.process(hook, request, params, user)
        expect(result).to eq(200)
      end

      context "when a gitlab_user_id is configured" do
        context "and the request user matches the configured user",
                with_settings: { plugin_openproject_gitlab_integration: { gitlab_user_id: 12 } } do
          it "returns 200" do
            expect(handler.process(hook, request, params, user)).to eq(200)
          end

          it "sends the notification" do
            handler.process(hook, request, params, user)
            expect(OpenProject::Notifications).to have_received(:send).with(:"gitlab.merge_request_hook", expected_params)
          end
        end

        context "and the request user does not match the configured user",
                with_settings: { plugin_openproject_gitlab_integration: { gitlab_user_id: 99 } } do
          it "returns 403" do
            expect(handler.process(hook, request, params, user)).to eq(403)
          end

          it "does not send a notification" do
            handler.process(hook, request, params, user)
            expect(OpenProject::Notifications).not_to have_received(:send)
          end
        end
      end

      context "when no gitlab_user_id is configured",
              with_settings: { plugin_openproject_gitlab_integration: {} } do
        it "returns 200 regardless of which user authenticates" do
          expect(handler.process(hook, request, params, user)).to eq(200)
        end
      end
    end
  end
end
