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
require "rack/test"

RSpec.describe API::V3::Backups::BackupsAPI, with_config: { backup_enabled: true } do
  include API::V3::Utilities::PathHelper

  let(:user) { create(:user, global_permissions: [:create_backup]) }
  let(:params) { { backupToken: backup_token.plain_value } }

  let(:backup_token) { create(:backup_token, user:) }

  before do
    login_as user
  end

  def create_backup
    post api_v3_paths.backups, params.to_json, "CONTENT_TYPE" => "application/json"
  end

  describe "POST /api/v3/backups" do
    shared_context "request" do
      before do
        create_backup
      end
    end

    context "with no pending backups" do
      context "with no params" do
        let(:params) { {} }

        include_context "request"

        it "results in a bad request error" do
          expect(last_response).to have_http_status :bad_request
        end
      end

      context "with no options" do
        before do
          expect(Backups::CreateService)
            .to receive(:new)
            .with(user:, backup_token: backup_token.plain_value, include_attachments: true)
            .and_call_original

          create_backup
        end

        it "enqueues the backup including attachments" do
          expect(last_response).to have_http_status :accepted
        end
      end

      context "with include_attachments: false" do
        let(:params) { { backupToken: backup_token.plain_value, attachments: false } }

        before do
          expect(Backups::CreateService)
            .to receive(:new)
            .with(user:, backup_token: backup_token.plain_value, include_attachments: false)
            .and_call_original

          create_backup
        end

        it "enqueues a backup not including attachments" do
          expect(last_response).to have_http_status :accepted
        end
      end
    end

    context "with pending backups" do
      let!(:backup) { create(:backup) }
      let!(:status) { create(:delayed_job_status, user:, reference: backup) }

      include_context "request"

      it "results in a conflict" do
        expect(last_response).to have_http_status :conflict
      end
    end

    context "with missing permissions" do
      let(:user) { create(:user) }

      include_context "request"

      it "is forbidden" do
        expect(last_response).to have_http_status :forbidden
      end
    end

    context "with another user's token" do
      let(:other_user) { create(:user) }
      let(:backup_token) { create(:backup_token, user: other_user) }

      include_context "request"

      it "is forbidden" do
        expect(last_response).to have_http_status :forbidden
      end
    end

    context "with daily backup limit reached", with_config: { backup_daily_limit: -1 } do
      include_context "request"

      it "is rate limited" do
        expect(last_response).to have_http_status :too_many_requests
      end
    end

    context "with backup token on cooldown", with_config: { backup_initial_waiting_period: 24.hours } do
      let(:backup_token) { create(:backup_token, :with_waiting_period, user:, since: 5.hours) }

      include_context "request"

      it "is forbidden" do
        expect(last_response).to have_http_status :forbidden
      end

      it "shows the remaining hours until the token is valid" do
        expect(last_response.body).to include "19 hours"
      end
    end
  end
end
