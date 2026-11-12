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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe "Subscriptions to OpenProject::Notification" do # rubocop:disable RSpec/DescribeClass
  describe "OpenIDConnect::UserTokens::FetchService::TOKEN_OBTAINED_EVENT" do
    subject(:notification_sent) do
      OpenProject::Notifications.send(
        OpenIDConnect::UserTokens::FetchService::TOKEN_OBTAINED_EVENT,
        token:,
        audience:
      )
    end

    let(:token) { create(:oidc_user_token) }
    let(:audience) { "the-storage-audience" }
    let(:id_create_result) { ServiceResult.success }

    let!(:storage) { create(:nextcloud_storage, storage_audience: "the-storage-audience") }

    before do
      allow(RemoteIdentities::CreateService).to receive(:call).and_return(id_create_result)
    end

    it "creates a remote identity" do
      notification_sent

      expect(RemoteIdentities::CreateService).to have_received(:call).with(user: token.user, integration: storage, token:)
    end

    context "when obtained token is for an audience that's not a storage" do
      let(:audience) { "not-the-storage-audience" }

      it "does not create a remote identity for the storage" do
        notification_sent

        expect(RemoteIdentities::CreateService).not_to have_received(:call)
      end
    end

    context "when creation of remote identity raises an error" do
      let(:error) { StandardError.new("ouch, that hurt") }

      before do
        allow(RemoteIdentities::CreateService).to receive(:call).and_raise(error)
      end

      it "raises the same error" do
        expect { notification_sent }.to raise_error(error)
      end
    end

    context "when creation of remote identity fails" do
      let(:id_create_result) { ServiceResult.failure(errors: StandardError.new(message)) }
      let(:message) { "ouch, that was bad" }

      before do
        allow(Rails.logger).to receive(:error)
      end

      it "raises no error" do
        expect { notification_sent }.not_to raise_error
      end

      it "logs an error" do
        notification_sent

        expect(Rails.logger).to have_received(:error).with(/#{message}/)
      end
    end
  end
end
