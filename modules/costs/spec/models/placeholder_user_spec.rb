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

require_relative "../spec_helper"

RSpec.describe PlaceholderUser do
  shared_let(:placeholder) { create(:placeholder_user) }
  shared_let(:project) { create(:project) }

  describe "rates" do
    it "carries default rates" do
      create(:default_hourly_rate, principal: placeholder, valid_from: 1.year.ago, rate: 95)

      expect(placeholder.default_rate_at(Date.current).rate).to eq(95)
    end

    it "carries project rates" do
      create(:hourly_rate, principal: placeholder, project:, valid_from: 1.year.ago, rate: 120)

      expect(placeholder.rate_at(Date.current, project).rate).to eq(120)
    end

    it "falls back to the default rate outside a rated project" do
      create(:default_hourly_rate, principal: placeholder, valid_from: 1.year.ago, rate: 95)

      expect(placeholder.rate_at(Date.current, project).rate).to eq(95)
    end
  end

  # A placeholder can never log time, so there is nothing to recost and the
  # entry-updating callbacks would only ever scan for rows that cannot exist.
  describe "cost recalculation" do
    it "is skipped when the rate belongs to a placeholder" do
      rate = build(:default_hourly_rate, principal: placeholder, valid_from: 1.year.ago)
      allow(rate).to receive(:rate_created)

      rate.save!

      expect(rate).not_to have_received(:rate_created)
    end

    it "still runs for a real user" do
      rate = build(:default_hourly_rate, principal: create(:user), valid_from: 1.year.ago)
      allow(rate).to receive(:rate_created)

      rate.save!

      expect(rate).to have_received(:rate_created)
    end
  end
end
