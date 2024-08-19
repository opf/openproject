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

RSpec.describe TableHelpers::TableParser do
  let(:parsed_data) { described_class.new.parse(table) }

  it "ignores empty decorative columns" do
    table = <<~TABLE
      | subject | description |
      | foo     | bar         |
    TABLE
    parsed_data = described_class.new.parse(table)
    expect(parsed_data.dig(0, :attributes).keys).to eq(%i[subject description])
  end

  it "normalizes column names to identifiers" do
    table = <<~TABLE
      |    DeScRiPtIoN   |
      |       value      |
    TABLE
    parsed_data = described_class.new.parse(table)
    expect(parsed_data.dig(0, :attributes).keys).to eq(%i[description])
  end

  it "ignores comments and empty lines" do
    table = <<~TABLE
      # this comment is ignored
      | subject |
      # this comment and the following empty line are ignored

      | value   |
    TABLE
    parsed_data = described_class.new.parse(table)
    expect(parsed_data.length).to eq(1)
  end

  it "raises a error if the header name is deprecated " \
     '(for example "remaining hours" instead of "remaining work")' do
    table = <<~TABLE
      subject | remaining hours
      wp      |              4h
    TABLE
    expect { described_class.new.parse(table) }
      .to raise_error(ArgumentError, 'Please use "remaining work" instead of "remaining hours"')
  end

  it "raises an error if there are more cells than headers in a row" do
    table = <<~TABLE
      subject | work
      wp      |   4h |   6h
    TABLE
    expect { described_class.new.parse(table) }
      .to raise_error(ArgumentError, "Too many cells in row 1, have you forgotten some headers?")
  end

  it "is ok to have more headers than cells (value of missing cells will be nil)" do
    table = <<~TABLE
      subject | work | remaining work
      wp      |   4h
    TABLE
    parsed_data = described_class.new.parse(table)
    expect(parsed_data.dig(0, :attributes, :estimated_hours)).to eq(4.0)
    expect(parsed_data.dig(0, :attributes, :remaining_hours)).to be_nil
  end

  describe "subject column" do
    let(:table) do
      <<~TABLE
        | subject      |
        | Work Package |
      TABLE
    end

    it "sets the subject attribute" do
      data = parsed_data.first
      expect(data.dig(:attributes, :subject)).to eq("Work Package")
    end

    it "sets the identifier as the subject snake-cased" do
      data = parsed_data.first
      expect(data[:identifier]).to eq(:work_package)
    end
  end

  describe "hierarchy column" do
    let(:table) do
      <<~TABLE
        hierarchy
        Parent
          Child
            Grand-Child
          Child 2
          Child 3
            Another child
        Root sibling
      TABLE
    end

    it "sets the parent attribute by its identifier" do
      attributes = parsed_data.flat_map { _1[:attributes] }
      expect(attributes.pluck(:parent)).to eq([nil, :parent, :child, :parent, :parent, :child3, nil])
    end

    it "sets the subject attribute" do
      attributes = parsed_data.flat_map { _1[:attributes] }
      expect(attributes.pluck(:subject))
        .to eq(["Parent", "Child", "Grand-Child", "Child 2", "Child 3", "Another child", "Root sibling"])
    end

    it "sets the identifier metadata as the subject snake-cased" do
      expect(parsed_data.pluck(:identifier))
        .to eq(%i[parent child grand_child child2 child3 another_child root_sibling])
    end
  end

  describe "remaining work column" do
    let(:table) do
      <<~TABLE
        subject | remaining work
        wp      |             9h
      TABLE
    end

    it "sets the derived remaining work attribute" do
      expect(parsed_data.first[:attributes]).to include(remaining_hours: 9)
    end
  end

  describe "derived remaining work column" do
    let(:table) do
      <<~TABLE
        subject | derived remaining work
        wp      |                     9h
      TABLE
    end

    it "sets the derived remaining work attribute" do
      expect(parsed_data.first[:attributes]).to include(derived_remaining_hours: 9)
    end
  end

  describe "status column" do
    let!(:status) { create(:status, name: "New") }
    let(:table) do
      <<~TABLE
        subject | status
        wp      | New
      TABLE
    end

    it "sets the status attribute to its name, to be looked up later" do
      expect(parsed_data.first[:attributes]).to include(status: "New")
    end
  end
end
