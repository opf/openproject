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

RSpec.describe Queries::Filters::Strategies::CfCalculatedValue do
  let(:filter) { instance_double(Queries::Filters::Base, operator: operator_symbol) }

  subject(:strategy) { described_class.new(filter) }

  describe ".supported_operators" do
    it "adds boolean operators on top of the float operators" do
      expect(described_class.supported_operators).to eq(%w[= ! >= <= =t =f !* *])
    end
  end

  describe "#operator" do
    subject(:operator) { strategy.operator }

    context "when the operator is >=" do
      let(:operator_symbol) { ">=" }

      it "maps to the calculated value GreaterOrEqual operator" do
        expect(operator).to eq(Queries::Operators::CustomFields::CalculatedValues::GreaterOrEqual)
      end
    end

    context "when the operator is <=" do
      let(:operator_symbol) { "<=" }

      it "maps to the calculated value LessOrEqual operator" do
        expect(operator).to eq(Queries::Operators::CustomFields::CalculatedValues::LessOrEqual)
      end
    end

    context "when the operator is =t" do
      let(:operator_symbol) { "=t" }

      it "maps to the IsTrue operator" do
        expect(operator).to eq(Queries::Operators::CustomFields::CalculatedValues::IsTrue)
      end
    end

    context "when the operator is =f" do
      let(:operator_symbol) { "=f" }

      it "maps to the IsFalse operator" do
        expect(operator).to eq(Queries::Operators::CustomFields::CalculatedValues::IsFalse)
      end
    end

    context "when the operator is =" do
      let(:operator_symbol) { "=" }

      it "keeps the plain equality operator" do
        expect(operator).to eq(Queries::Operators::Equals)
      end
    end
  end
end
