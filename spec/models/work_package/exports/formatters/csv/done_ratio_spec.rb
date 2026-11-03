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
#++

require "spec_helper"

RSpec.describe WorkPackage::Exports::Formatters::CSV::DoneRatio do
  it "handles both percentage columns only in CSV" do
    expect(described_class.apply?(:done_ratio, :csv)).to be true
    expect(described_class.apply?(:derived_done_ratio, :csv)).to be true
    expect(described_class.apply?(:done_ratio, :xls)).to be false
  end

  it "exports the percentage as a fraction" do
    formatter = described_class.new(:done_ratio)

    expect(formatter.format_value(25, {})).to eq(0.25)
    expect(formatter.format_value(0, {})).to eq(0.0)
    expect(formatter.format_value(nil, {})).to be_nil
  end

  it "is selected for CSV without changing the XLS formatter" do
    expect(Exports::Register.formatter_for(WorkPackage, :done_ratio, :csv)).to be_a(described_class)
    expect(Exports::Register.formatter_for(WorkPackage, :done_ratio, :xls))
      .to be_a(WorkPackage::Exports::Formatters::XLS::DoneRatio)
  end
end
