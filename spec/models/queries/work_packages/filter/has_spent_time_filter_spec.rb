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

RSpec.describe Queries::WorkPackages::Filter::HasSpentTimeFilter do
  let(:filter) { described_class.create!(name: :has_spent_time, operator: "<>d", values: ["2024-01-01", "2024-01-31"]) }

  describe ".key" do
    it "is :has_spent_time" do
      expect(described_class.key).to eq(:has_spent_time)
    end
  end

  describe "#type" do
    it "is :date" do
      expect(filter.type).to eq(:date)
    end
  end

  describe "#available_operators" do
    it "only exposes BetweenDate" do
      expect(filter.available_operators).to eq([Queries::Operators::BetweenDate])
    end
  end

  describe "#where" do
    context "with valid from and to dates" do
      it "returns an EXISTS subquery" do
        sql = filter.where
        expect(sql).to include("EXISTS")
        expect(sql).to include("time_entries.entity_type = 'WorkPackage'")
        expect(sql).to include("time_entries.hours > 0")
        expect(sql).to include("time_entries.ongoing = false")
      end
    end

    context "with blank values" do
      let(:filter) { described_class.create!(name: :has_spent_time, operator: "<>d", values: ["", ""]) }

      it "returns nil" do
        expect(filter.where).to be_nil
      end
    end

    context "with no values" do
      let(:filter) { described_class.create!(name: :has_spent_time, operator: "<>d", values: []) }

      it "returns nil" do
        expect(filter.where).to be_nil
      end
    end

    context "with an invalid date string" do
      let(:filter) { described_class.create!(name: :has_spent_time, operator: "<>d", values: ["not-a-date", "2024-01-31"]) }

      it "returns nil instead of raising" do
        expect(filter.where).to be_nil
      end
    end
  end
end
