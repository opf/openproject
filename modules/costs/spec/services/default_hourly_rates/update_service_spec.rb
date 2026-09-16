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

RSpec.describe DefaultHourlyRates::UpdateService, type: :model do
  shared_let(:project) { create(:project) }

  shared_let(:principal) { create(:user) }
  shared_let(:admin) { create(:admin) }
  shared_let(:manager) { create(:user, member_with_permissions: { project => %i[edit_hourly_rates] }) }

  let(:rate) { create(:default_hourly_rate, principal: rate_owner, rate: 50, valid_from: Date.new(2025, 1, 1)) }
  let(:rate_owner) { principal }

  subject(:service_result) do
    described_class.new(user: current_user, model: rate).call(rate: "120")
  end

  context "as an admin" do
    let(:current_user) { admin }

    it "applies the new rate" do
      expect(service_result).to be_success
      expect(rate.reload.rate).to eq(120)
    end
  end

  context "as a locked admin" do
    let(:current_user) { create(:admin, status: User.statuses[:locked]) }

    it "is refused" do
      expect(service_result).to be_failure
      expect(service_result.errors.symbols_for(:base)).to include(:error_unauthorized)
      expect(rate.reload.rate).to eq(50)
    end
  end

  # edit_hourly_rates is scoped to a project, and a default rate has none to
  # scope to.
  context "with project rate permissions" do
    let(:current_user) { manager }

    it "is refused" do
      expect(service_result).to be_failure
      expect(service_result.errors.symbols_for(:base)).to include(:error_unauthorized)
      expect(rate.reload.rate).to eq(50)
    end
  end

  context "with project rate permissions, for their own default rate" do
    let(:current_user) { manager }
    let(:rate_owner) { manager }

    it "is refused" do
      expect(service_result).to be_failure
      expect(rate.reload.rate).to eq(50)
    end
  end
end
