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

RSpec.describe Queries::Operators::CustomFields::CalculatedValues::LessOrEqual do
  subject(:sql) { described_class.sql_for_field(values, db_table, db_field) }

  let(:values) { ["5"] }
  let(:db_table) { "custom_values" }
  let(:db_field) { "value" }

  describe ".symbol" do
    it "is <=" do
      expect(described_class.symbol).to eq("<=")
    end
  end

  describe ".sql_for_field" do
    it "casts the value and compares it with the numeric operand" do
      expect(sql).to eq(
        "CASE WHEN custom_values.value NOT IN ('', 't', 'f') " \
        "THEN CAST(custom_values.value AS decimal(60,4)) <= 5.0 END"
      )
    end

    it "guards boolean and empty rows so they never match the numeric comparison" do
      # The CASE guard excludes the stored boolean literals ('t'/'f') and the
      # empty string, leaving them as NULL (not a match) rather than casting them.
      expect(sql).to include("NOT IN ('', 't', 'f')")
    end

    it "coerces the operand to a float" do
      expect(described_class.sql_for_field(["3.5"], db_table, db_field))
        .to include("<= 3.5 END")
    end
  end
end
