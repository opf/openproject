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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe Queries::Operators::DateRangeClauses do
  let(:instance) do
    Class.new { def connection; end }.include(described_class).new
  end

  let(:connection) { WorkPackage.connection }

  let(:today) { Date.new(2024, 11, 5) }
  let(:smallest_date) { Date.new(-4712, 1, 1) }
  let(:biggest_date) { Date.new(294276, 12, 31) }

  before do
    allow(instance).to receive(:connection).and_return(connection)
    allow(Time).to receive(:zone).and_return(instance_double(ActiveSupport::TimeZone, today:))
  end

  describe "#relative_date_range_clause and #date_range_clause" do
    shared_examples "returns sql" do |expected|
      it "returns expected sql from relative_date_range_clause" do
        expect(instance.relative_date_range_clause(:some_table, :some_field, from, to))
          .to eq(expected)
      end

      it "returns expected sql from date_range_clause" do
        from_date = from && (today + from)
        to_date = to && (today + to)

        expect(instance.date_range_clause(:some_table, :some_field, from_date, to_date))
          .to eq(expected)
      end
    end

    shared_examples "doesn't error in database" do
      it "returns sql from relative_date_range_clause that doesn't error in database" do
        sql = instance.relative_date_range_clause(WorkPackage.table_name, :created_at, from, to)

        expect { WorkPackage.where(sql).to_a }.not_to raise_error
      end

      it "returns sql from date_range_clause that doesn't error in database" do
        from_date = from && (today + from)
        to_date = to && (today + to)
        sql = instance.date_range_clause(WorkPackage.table_name, :created_at, from_date, to_date)

        expect { WorkPackage.where(sql).to_a }.not_to raise_error
      end
    end

    context "when both values are provided" do
      let(:from) { -1 }
      let(:to) { +1 }

      include_examples "returns sql", <<-SQL.squish
        some_table.some_field > '2024-11-03 23:59:59.999999'
        AND some_table.some_field <= '2024-11-06 23:59:59.999999'
      SQL
    end

    context "when only from is provided" do
      let(:from) { -1 }
      let(:to) { nil }

      include_examples "returns sql", "some_table.some_field > '2024-11-03 23:59:59.999999'"
    end

    context "when only to is provided" do
      let(:from) { nil }
      let(:to) { +1 }

      include_examples "returns sql", "some_table.some_field <= '2024-11-06 23:59:59.999999'"
    end

    context "when none is provided" do
      let(:from) { nil }
      let(:to) { nil }

      include_examples "returns sql", "1 = 1"
    end

    context "when from is around extrema" do
      let(:to) { 0 }

      context "when from is minimum allowed date" do
        let(:from) { smallest_date - today }

        include_examples "returns sql", <<-SQL.squish
          some_table.some_field > '4714-12-31 23:59:59.999999 BC'
          AND some_table.some_field <= '2024-11-05 23:59:59.999999'
        SQL

        include_examples "doesn't error in database"
      end

      context "when from is less than minimum allowed date" do
        let(:from) { smallest_date - today - 1 }

        include_examples "returns sql", "some_table.some_field <= '2024-11-05 23:59:59.999999'"
      end

      context "when from is maximum allowed date" do
        let(:from) { biggest_date - today }

        include_examples "returns sql", <<-SQL.squish
          some_table.some_field > '294276-12-30 23:59:59.999999'
          AND some_table.some_field <= '2024-11-05 23:59:59.999999'
        SQL

        include_examples "doesn't error in database"
      end

      context "when from is more than maximum allowed date" do
        let(:from) { biggest_date - today + 1 }

        include_examples "returns sql", "1 <> 1"
      end
    end

    context "when to is around extrema" do
      let(:from) { 0 }

      context "when to is minimum allowed date" do
        let(:to) { smallest_date - today }

        include_examples "returns sql", <<-SQL.squish
          some_table.some_field > '2024-11-04 23:59:59.999999'
          AND some_table.some_field <= '4713-01-01 23:59:59.999999 BC'
        SQL

        include_examples "doesn't error in database"
      end

      context "when to is less than minimum allowed date" do
        let(:to) { smallest_date - today - 1 }

        include_examples "returns sql", "1 <> 1"
      end

      context "when to is maximum allowed date" do
        let(:to) { biggest_date - today }

        include_examples "returns sql", <<-SQL.squish
          some_table.some_field > '2024-11-04 23:59:59.999999'
          AND some_table.some_field <= '294276-12-31 23:59:59.999999'
        SQL

        include_examples "doesn't error in database"
      end

      context "when to is more than maximum allowed date" do
        let(:to) { biggest_date - today + 1 }

        include_examples "returns sql", "some_table.some_field > '2024-11-04 23:59:59.999999'"
      end
    end
  end
end
