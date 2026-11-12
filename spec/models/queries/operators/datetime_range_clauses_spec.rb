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

RSpec.describe Queries::Operators::DatetimeRangeClauses do
  let(:instance) do
    Class.new { def connection; end }.include(described_class).new
  end

  let(:connection) { WorkPackage.connection }

  let(:today) { DateTime.new(2024, 11, 5, 12, 34, 56789/1000r) }
  let(:smallest_date) { DateTime.new(-4712, 1, 1, 12, 34, 56789/1000r) }
  let(:biggest_date) { DateTime.new(294276, 12, 31, 12, 34, 56789/1000r) }

  before do
    allow(instance).to receive(:connection).and_return(connection)
    allow(Time).to receive(:zone).and_return(instance_double(ActiveSupport::TimeZone, today:))
  end

  describe "#datetime_range_clause" do
    shared_examples "returns sql" do |expected|
      it "returns expected sql" do
        expect(instance.datetime_range_clause(:some_table, :some_field, from, to))
          .to eq(expected)
      end
    end

    shared_examples "doesn't error in database" do
      it "returns sql that doesn't error in database" do
        sql = instance.datetime_range_clause(WorkPackage.table_name, :created_at, from, to)

        expect { WorkPackage.where(sql).to_a }.not_to raise_error
      end
    end

    context "when both values are provided" do
      let(:from) { today - 1 }
      let(:to) { today + 1 }

      include_examples "returns sql", <<-SQL.squish
        some_table.some_field >= '2024-11-04 12:34:56.789000'
        AND some_table.some_field <= '2024-11-06 12:34:56.789000'
      SQL
    end

    context "when only from is provided" do
      let(:from) { today - 1 }
      let(:to) { nil }

      include_examples "returns sql", "some_table.some_field >= '2024-11-04 12:34:56.789000'"
    end

    context "when only to is provided" do
      let(:from) { nil }
      let(:to) { today + 1 }

      include_examples "returns sql", "some_table.some_field <= '2024-11-06 12:34:56.789000'"
    end

    context "when none is provided" do
      let(:from) { nil }
      let(:to) { nil }

      include_examples "returns sql", "1 = 1"
    end

    context "when from is around extrema" do
      let(:to) { today }

      context "when from is minimum allowed date" do
        let(:from) { smallest_date }

        include_examples "returns sql", <<-SQL.squish
          some_table.some_field >= '4713-01-01 12:34:56.789000 BC'
          AND some_table.some_field <= '2024-11-05 12:34:56.789000'
        SQL

        include_examples "doesn't error in database"
      end

      context "when from is less than minimum allowed date" do
        let(:from) { smallest_date - 1 }

        include_examples "returns sql", "some_table.some_field <= '2024-11-05 12:34:56.789000'"
      end

      context "when from is maximum allowed date" do
        let(:from) { biggest_date }

        include_examples "returns sql", <<-SQL.squish
          some_table.some_field >= '294276-12-31 12:34:56.789000'
          AND some_table.some_field <= '2024-11-05 12:34:56.789000'
        SQL

        include_examples "doesn't error in database"
      end

      context "when from is more than maximum allowed date" do
        let(:from) { biggest_date + 1 }

        include_examples "returns sql", "1 <> 1"
      end
    end

    context "when to is around extrema" do
      let(:from) { today }

      context "when to is minimum allowed date" do
        let(:to) { smallest_date }

        include_examples "returns sql", <<-SQL.squish
          some_table.some_field >= '2024-11-05 12:34:56.789000'
          AND some_table.some_field <= '4713-01-01 12:34:56.789000 BC'
        SQL

        include_examples "doesn't error in database"
      end

      context "when to is less than minimum allowed date" do
        let(:to) { smallest_date - 1 }

        include_examples "returns sql", "1 <> 1"
      end

      context "when to is maximum allowed date" do
        let(:to) { biggest_date }

        include_examples "returns sql", <<-SQL.squish
          some_table.some_field >= '2024-11-05 12:34:56.789000'
          AND some_table.some_field <= '294276-12-31 12:34:56.789000'
        SQL

        include_examples "doesn't error in database"
      end

      context "when to is more than maximum allowed date" do
        let(:to) { biggest_date + 1 }

        include_examples "returns sql", "some_table.some_field >= '2024-11-05 12:34:56.789000'"
      end
    end
  end
end
