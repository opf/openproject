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

RSpec.describe JsonSchemaLoader do
  subject { described_class.new(base_path: "spec/fixtures/files").load("test_schema") }

  it "loads the schema as a aymbolized hash" do
    expect(subject.dig(:properties, :foo, :type)).to eq("string")
  end

  it "resolves $ref attributes" do
    expect(subject.dig(:properties, :referenced, :description)).to eq("This is a referenced value.")
  end

  it "resolves $ref attributes inside arrays" do
    expect(subject.dig(:properties, :combined, :allOf, 1, :description)).to eq("This is a referenced value.")
  end
end
