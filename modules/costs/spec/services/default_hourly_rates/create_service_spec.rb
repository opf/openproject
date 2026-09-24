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

RSpec.describe DefaultHourlyRates::CreateService, type: :model do
  shared_let(:project) { create(:project) }

  shared_let(:principal) { create(:user) }
  shared_let(:admin) { create(:admin) }
  shared_let(:manager) { create(:user, member_with_permissions: { project => %i[edit_hourly_rates] }) }
  shared_let(:self_manager) { create(:user, member_with_permissions: { project => %i[edit_own_hourly_rate] }) }

  subject(:service_result) do
    described_class
      .new(user: current_user)
      .call(user_id: target.id, valid_from: "2026-01-01", rate: "95")
  end

  let(:target) { principal }

  context "as an admin" do
    let(:current_user) { admin }

    it "creates the rate" do
      expect { service_result }.to change { principal.default_rates.count }.by(1)

      expect(service_result).to be_success
      expect(service_result.result.rate).to eq(95)
    end
  end

  context "with the global manage_default_hourly_rates permission" do
    let(:current_user) { create(:user, global_permissions: %i[manage_default_hourly_rates]) }

    it "creates the rate without being an admin" do
      expect { service_result }.to change { principal.default_rates.count }.by(1)

      expect(service_result).to be_success
    end
  end

  context "as a locked admin" do
    let(:current_user) { create(:admin, status: User.statuses[:locked]) }

    it "is refused" do
      expect { service_result }.not_to change(DefaultHourlyRate, :count)

      expect(service_result).to be_failure
      expect(service_result.errors.symbols_for(:base)).to include(:error_unauthorized)
    end
  end

  # edit_own_hourly_rate and edit_hourly_rates are scoped to a project, and a
  # default rate has none to scope to.
  context "with project rate permissions" do
    let(:current_user) { manager }

    it "is refused" do
      expect { service_result }.not_to change(DefaultHourlyRate, :count)

      expect(service_result).to be_failure
      expect(service_result.errors.symbols_for(:base)).to include(:error_unauthorized)
    end
  end

  context "with edit_own_hourly_rate, for their own default rate" do
    let(:current_user) { self_manager }
    let(:target) { self_manager }

    it "is refused" do
      expect { service_result }.not_to change(DefaultHourlyRate, :count)

      expect(service_result).to be_failure
      expect(service_result.errors.symbols_for(:base)).to include(:error_unauthorized)
    end
  end
end
