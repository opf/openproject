#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2021 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'
require 'rack/test'

describe API::V3::Backups::BackupsAPI, type: :request do
  include API::V3::Utilities::PathHelper

  let(:user) { FactoryBot.create :user, global_permissions: [:create_backup] }
  let(:params) { {} }

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
        before do
          expect(Backups::CreateService)
            .to receive(:new)
            .with(user: user, include_attachments: true)
            .and_call_original

          create_backup
        end

        it "enqueues the backup including attachments" do
          expect(last_response.status).to eq 202
        end
      end

      context "with include_attachments: false" do
        let(:params) { { attachments: false } }

        before do
          expect(Backups::CreateService)
            .to receive(:new)
            .with(user: user, include_attachments: false)
            .and_call_original
          
          create_backup
        end

        it "enqueues a backup not including attachments" do
          expect(last_response.status).to eq 202
        end
      end
    end

    context "with pending backups" do
      let!(:backup) { FactoryBot.create :backup }
      let!(:status) { FactoryBot.create :delayed_job_status, user: user, reference: backup }

      include_context "request"

      it "results in a conflict" do
        expect(last_response.status).to eq 409
      end
    end

    context "with missing permissions" do
      let(:user) { FactoryBot.create :user }

      include_context "request"

      it "is forbidden" do
        expect(last_response.status).to eq 403
      end
    end
  end
end
