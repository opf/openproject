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

RSpec.describe Queries::Operators::Versions::LockedStatus do
  describe ".label_key" do
    it "returns the correct label key" do
      expect(described_class.label_key).to eq("label_locked")
    end
  end

  describe ".symbol" do
    it "returns the correct symbol" do
      expect(described_class.symbol).to eq("l")
    end
  end

  describe ".requires_value?" do
    it "does not require a value" do
      expect(described_class.requires_value?).to be false
    end
  end

  describe ".sql_for_field" do
    it "returns the correct SQL condition" do
      expected_sql = "#{Version.table_name}.status = 'locked'"

      expect(described_class.sql_for_field([], nil, nil))
        .to eq(expected_sql)
    end
  end

  describe ".human_name" do
    it "returns the localized name" do
      expect(described_class.human_name).to eq(I18n.t("label_locked"))
    end
  end

  describe ".to_sym" do
    it "returns the symbol as a symbol" do
      expect(described_class.to_sym).to eq(:l)
    end
  end

  describe ".to_query" do
    it "returns the URL-escaped symbol" do
      expect(described_class.to_query).to eq("l")
    end
  end
end
