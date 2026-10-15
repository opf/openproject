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

RSpec.describe HourlyRates::UpdateService, type: :model do
  shared_let(:project) { create(:project) }

  shared_let(:colleague) { create(:user, member_with_permissions: { project => %i[view_work_packages] }) }
  shared_let(:manager) { create(:user, member_with_permissions: { project => %i[edit_hourly_rates] }) }
  shared_let(:self_manager) { create(:user, member_with_permissions: { project => %i[edit_own_hourly_rate] }) }
  shared_let(:viewer) { create(:user, member_with_permissions: { project => %i[view_hourly_rates] }) }

  let(:rate) { create(:hourly_rate, principal:, project:, rate: 50, valid_from: Date.new(2025, 1, 1)) }

  subject(:service_result) do
    described_class.new(user: current_user, model: rate).call(rate: "120")
  end

  context "with edit_hourly_rates" do
    let(:current_user) { manager }
    let(:principal) { colleague }

    it "applies the new rate" do
      expect(service_result).to be_success
      expect(rate.reload.rate).to eq(120)
    end
  end

  context "with edit_own_hourly_rate" do
    let(:current_user) { self_manager }

    context "for their own rate" do
      let(:principal) { self_manager }

      it "applies the new rate" do
        expect(service_result).to be_success
        expect(rate.reload.rate).to eq(120)
      end
    end

    context "for someone else's rate" do
      let(:principal) { colleague }

      it "is refused" do
        expect(service_result).to be_failure
        expect(service_result.errors.symbols_for(:base)).to include(:error_unauthorized)
        expect(rate.reload.rate).to eq(50)
      end
    end
  end

  context "with view_hourly_rates only" do
    let(:current_user) { viewer }
    let(:principal) { colleague }

    it "is refused" do
      expect(service_result).to be_failure
      expect(service_result.errors.symbols_for(:base)).to include(:error_unauthorized)
      expect(rate.reload.rate).to eq(50)
    end
  end
end
