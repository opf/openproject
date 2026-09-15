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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require_relative "../../spec_helper"

RSpec.describe HourlyRates::CreateService, type: :model do
  shared_let(:project) { create(:project) }

  shared_let(:colleague) { create(:user, member_with_permissions: { project => %i[view_work_packages] }) }
  shared_let(:manager) { create(:user, member_with_permissions: { project => %i[edit_hourly_rates] }) }
  shared_let(:self_manager) { create(:user, member_with_permissions: { project => %i[edit_own_hourly_rate] }) }
  shared_let(:viewer) { create(:user, member_with_permissions: { project => %i[view_hourly_rates] }) }

  subject(:service_result) do
    described_class
      .new(user: current_user)
      .call(user_id: principal.id, project_id: project.id, valid_from: "2026-01-01", rate: "95")
  end

  context "with edit_hourly_rates" do
    let(:current_user) { manager }
    let(:principal) { colleague }

    it "creates the rate" do
      expect { service_result }.to change { colleague.rates.where(project:).count }.by(1)

      expect(service_result).to be_success
      expect(service_result.result.rate).to eq(95)
    end
  end

  context "with edit_own_hourly_rate" do
    let(:current_user) { self_manager }

    context "for their own rate" do
      let(:principal) { self_manager }

      it "creates the rate" do
        expect { service_result }.to change { self_manager.rates.where(project:).count }.by(1)

        expect(service_result).to be_success
      end
    end

    context "for someone else's rate" do
      let(:principal) { colleague }

      it "is refused" do
        expect { service_result }.not_to change(HourlyRate, :count)

        expect(service_result).to be_failure
        expect(service_result.errors.symbols_for(:base)).to include(:error_unauthorized)
      end
    end
  end

  context "with view_hourly_rates only" do
    let(:current_user) { viewer }
    let(:principal) { colleague }

    it "is refused" do
      expect { service_result }.not_to change(HourlyRate, :count)

      expect(service_result).to be_failure
      expect(service_result.errors.symbols_for(:base)).to include(:error_unauthorized)
    end
  end
end
