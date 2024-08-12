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

RSpec.describe Queries::Filters::Base do
  let(:integer_filter) do
    filter_class = Class.new(described_class) do
      def type
        :integer
      end

      def self.name
        "TestIntegerFilter"
      end
    end

    filter_class.create! name: :test_integer
  end

  let(:date_filter) do
    filter_class = Class.new(described_class) do
      def type
        :date
      end

      def self.name
        "TestDateFilter"
      end
    end

    filter_class.create! name: :test_date
  end

  let(:datetime_past_filter) do
    filter_class = Class.new(described_class) do
      def type
        :datetime_past
      end

      def self.name
        "TestDatetimePastFilter"
      end
    end

    filter_class.create! name: :test_datetime
  end

  shared_examples_for "validity checked" do
    describe "#valid?" do
      context "when the operator does not require values" do
        before do
          filter.operator = operator_without_value
        end

        it "is valid if no values are given" do
          expect(filter).to be_valid
        end
      end

      context "when the operator requires values" do
        before do
          filter.operator = valid_operator
        end

        context "and no value is given" do
          it "is invalid" do
            expect(filter).to be_invalid
          end
        end

        context "and only an empty string is given as value" do
          before do
            filter.values = [""]
          end

          it "is invalid" do
            expect(filter).to be_invalid
          end
        end

        context "and values are given" do
          before do
            filter.values = valid_values
          end

          it "is valid" do
            expect(filter).to be_valid
          end
        end
      end
    end
  end

  shared_examples_for "date validity checked" do
    describe "#valid?" do
      context "and the operator is 't' (today)" do
        before do
          filter.operator = "t"
        end

        it "is valid" do
          expect(filter).to be_valid
        end
      end

      context "and the operator is 'w' (this week)" do
        before do
          filter.operator = "w"
        end

        it "is valid" do
          expect(filter).to be_valid
        end
      end

      context "and the operator compares the current day" do
        before do
          filter.operator = ">t-"
        end

        context "and the value is an integer" do
          before do
            filter.values = ["4"]
          end

          it "is valid" do
            expect(filter).to be_valid
          end
        end

        context "and the value is not an integer" do
          before do
            filter.values = ["four"]
          end

          it "is invalid" do
            expect(filter).to be_invalid
          end
        end
      end
    end
  end

  context "for an integer filter" do
    let(:filter) { integer_filter }
    let(:valid_values) { [5] }
    let(:valid_operator) { "=" }
    let(:operator_without_value) { "*" }

    it_behaves_like "validity checked"

    describe "#valid?" do
      context "when the filter values is not an integer" do
        before do
          filter.operator = "="
          filter.values == [1, "asdf"]
        end

        it "is invalid" do
          expect(filter).to be_invalid
        end
      end
    end
  end

  context "for a date filter" do
    let(:filter) { date_filter }
    let(:valid_values) { [5] }
    let(:valid_operator) { "<t+" }
    let(:operator_without_value) { "t" }

    it_behaves_like "validity checked"
    it_behaves_like "date validity checked"
  end

  context "for a datetime_past filter" do
    let(:filter) { datetime_past_filter }
    let(:valid_values) { [5] }
    let(:valid_operator) { "<t-" }
    let(:operator_without_value) { "t" }

    it_behaves_like "validity checked"
    it_behaves_like "date validity checked"
  end
end
