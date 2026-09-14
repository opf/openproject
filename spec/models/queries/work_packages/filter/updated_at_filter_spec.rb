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

RSpec.describe Queries::WorkPackages::Filter::UpdatedAtFilter do
  describe "filtering work packages" do
    let(:reference_time) { Time.utc(2025, 1, 8, 12) }
    let!(:updated_today) { create(:work_package, updated_at: reference_time) }
    let!(:updated_three_days_ago) { create(:work_package, updated_at: reference_time - 3.days) }
    let!(:updated_five_days_ago) { create(:work_package, updated_at: reference_time - 5.days) }
    let(:instance) do
      described_class.create!(name: :updated_at, operator:, values:)
    end

    subject(:results) { WorkPackage.where(instance.where) }

    context "with an on-date filter" do
      let(:operator) { "=d" }
      let(:values) { ["2025-01-08T00:00:00Z"] }

      it "finds work packages updated on that date" do
        expect(results).to contain_exactly(updated_today)
      end
    end

    context "with both boundaries" do
      let(:operator) { "<>d" }
      let(:values) { ["2025-01-04T00:00:00Z", "2025-01-06T23:59:59Z"] }

      it "finds work packages within the range" do
        expect(results).to contain_exactly(updated_three_days_ago)
      end
    end

    context "with only the lower boundary" do
      let(:operator) { "<>d" }
      let(:values) { ["2025-01-05T00:00:00Z"] }

      it "finds work packages on or after the boundary" do
        expect(results).to contain_exactly(updated_today, updated_three_days_ago)
      end
    end

    context "with only the upper boundary" do
      let(:operator) { "<>d" }
      let(:values) { ["", "2025-01-04T23:59:59Z"] }

      it "finds work packages on or before the boundary" do
        expect(results).to contain_exactly(updated_five_days_ago)
      end
    end
  end

  it_behaves_like "basic query filter" do
    let(:type) { :datetime_past }
    let(:class_key) { :updated_at }

    describe "#available?" do
      it "is true" do
        expect(instance).to be_available
      end
    end

    describe "#allowed_values" do
      it "is nil" do
        expect(instance.allowed_values).to be_nil
      end
    end

    it_behaves_like "non ar filter"
  end
end
