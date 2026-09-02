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

RSpec.describe Queries::Filters::Strategies::CfDate do
  let(:filter) { instance_double(Queries::Filters::Base, operator: operator_symbol) }

  subject(:strategy) { described_class.new(filter) }

  describe ".supported_operators" do
    it "adds asking for a value to the date operators, which offered only its absence" do
      expect(described_class.supported_operators).to include("*", "!*")
    end
  end

  describe "#operator" do
    subject(:operator) { strategy.operator }

    # A custom value keeps its value in a string column, whatever the format, so an empty
    # string is how "no value" is stored.
    context "when the operator is *" do
      let(:operator_symbol) { "*" }

      it "maps to the operator that also excludes the empty string" do
        expect(operator).to eq(Queries::Operators::AllAndNonBlank)
      end
    end

    context "when the operator is !*" do
      let(:operator_symbol) { "!*" }

      it "maps to the operator that also counts the empty string as absent" do
        expect(operator).to eq(Queries::Operators::NoneOrBlank)
      end
    end
  end
end
