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

RSpec.describe Queries::Operators::CustomFields::CalculatedValues::IsFalse do
  describe ".symbol" do
    it "is =f" do
      expect(described_class.symbol).to eq("=f")
    end
  end

  describe ".requires_value?" do
    it "does not require a value" do
      expect(described_class.requires_value?).to be(false)
    end
  end

  describe ".sql_for_field" do
    it "matches rows storing the boolean false literal" do
      expect(described_class.sql_for_field([], "custom_values", "value"))
        .to eq("custom_values.value = 'f'")
    end

    it "ignores any supplied values" do
      expect(described_class.sql_for_field(["ignored"], "custom_values", "value"))
        .to eq("custom_values.value = 'f'")
    end
  end
end
