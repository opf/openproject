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
require "services/base_services/behaves_like_create_service"

RSpec.describe AdminElevationSessions::CreateService, type: :model do
  it_behaves_like "BaseServices create service"

  context "with admin privilege elevation required", with_flag: { admin_privilege_elevation: true } do
    shared_let(:admin) { create(:admin) }
    shared_let(:project) { create(:project) }

    let(:user) { admin }
    let(:params) { { project:, session_id: "session", confirmed_with: "password", include_subprojects: true } }

    subject(:result) { described_class.new(user:).call(params) }

    it "creates an elevation session for the acting admin", :aggregate_failures do
      freeze_time do
        expect(result).to be_success
        expect(result.result).to be_persisted
        expect(result.result).to have_attributes(user: admin,
                                                 project:,
                                                 session_id: "session",
                                                 confirmed_with: "password",
                                                 include_subprojects: true,
                                                 last_used_at: Time.current,
                                                 ended_at: nil)
      end
    end

    context "with an active elevation session for the project in the same session" do
      let!(:existing) { create(:admin_elevation_session, user: admin, project:, session_id: "session") }

      it "returns the existing elevation session", :aggregate_failures do
        expect(result).to be_success
        expect(result.result).to eq(existing)
      end

      it "does not create another elevation session" do
        expect { result }.not_to change(AdminElevationSession, :count)
      end
    end

    context "with an active elevation session for the project in another session" do
      let!(:existing) { create(:admin_elevation_session, user: admin, project:, session_id: "other") }

      it "creates a new elevation session", :aggregate_failures do
        expect { result }.to change(AdminElevationSession, :count).by(1)
        expect(result.result).not_to eq(existing)
      end
    end

    context "with an ended elevation session for the project in the same session" do
      let!(:existing) do
        create(:admin_elevation_session, user: admin, project:, session_id: "session", ended_at: Time.current)
      end

      it "creates a new elevation session", :aggregate_failures do
        expect { result }.to change(AdminElevationSession, :count).by(1)
        expect(result.result).not_to eq(existing)
      end
    end

    context "with an idle elevation session for the project in the same session" do
      let!(:existing) do
        create(:admin_elevation_session, user: admin, project:, session_id: "session", last_used_at: 1.day.ago)
      end

      it "creates a new elevation session", :aggregate_failures do
        expect { result }.to change(AdminElevationSession, :count).by(1)
        expect(result.result).not_to eq(existing)
      end
    end

    context "for a regular user" do
      let(:user) { create(:user) }

      it "fails without creating an elevation session", :aggregate_failures do
        expect { result }.not_to change(AdminElevationSession, :count)
        expect(result).to be_failure
      end
    end

    context "with the feature flag inactive", with_flag: { admin_privilege_elevation: false } do
      it "fails without creating an elevation session", :aggregate_failures do
        expect { result }.not_to change(AdminElevationSession, :count)
        expect(result).to be_failure
      end
    end
  end
end
