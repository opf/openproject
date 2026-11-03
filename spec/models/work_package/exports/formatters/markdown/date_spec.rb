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

RSpec.describe WorkPackage::Exports::Formatters::Markdown::Date do
  subject(:formatter) { described_class.new(:date) }

  def format(start_date:, due_date:)
    formatter.format(build(:work_package, start_date:, due_date:))
  end

  it "prints the ISO date range" do
    expect(format(start_date: "2024-05-30", due_date: "2025-03-13")).to eq("2024-05-30 – 2025-03-13")
  end

  it "prints one date when both are equal" do
    expect(format(start_date: "2024-05-30", due_date: "2024-05-30")).to eq("2024-05-30")
  end

  it "prints an open-ended range when only the start date is set" do
    expect(format(start_date: "2024-05-30", due_date: nil)).to eq("2024-05-30 – ")
  end

  it "prints an open-started range when only the due date is set" do
    expect(format(start_date: nil, due_date: "2024-05-30")).to eq(" – 2024-05-30")
  end

  it "prints an empty string when both are missing" do
    expect(format(start_date: nil, due_date: nil)).to eq("")
  end

  describe "start_date" do
    subject(:formatter) { described_class.new(:start_date) }

    it "prints the ISO date" do
      expect(formatter.format(build(:work_package, start_date: "2024-05-30"))).to eq("2024-05-30")
    end

    it "prints an empty string when missing" do
      expect(formatter.format(build(:work_package, start_date: nil))).to eq("")
    end
  end

  describe "due_date" do
    subject(:formatter) { described_class.new(:due_date) }

    it "prints the ISO date" do
      expect(formatter.format(build(:work_package, due_date: "2025-03-13"))).to eq("2025-03-13")
    end

    it "prints an empty string when missing" do
      expect(formatter.format(build(:work_package, due_date: nil))).to eq("")
    end
  end

  it { expect(Exports::Register.formatter_for(WorkPackage, :date, :md)).to be_a(described_class) }
  it { expect(Exports::Register.formatter_for(WorkPackage, :start_date, :md)).to be_a(described_class) }
  it { expect(Exports::Register.formatter_for(WorkPackage, :due_date, :md)).to be_a(described_class) }
  it { expect(Exports::Register.formatter_for(WorkPackage, :date, :csv)).not_to be_a(described_class) }
  it { expect(Exports::Register.formatter_for(WorkPackage, :due_date, :csv)).not_to be_a(described_class) }
end
