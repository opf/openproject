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

RSpec.describe WorkPackage::Exports::Formatters::Markdown::DateTime do
  let(:timestamp) { Time.zone.parse("2024-05-30T14:15:16Z") }

  describe "created_at" do
    subject(:formatter) { described_class.new(:created_at) }

    it "prints the ISO timestamp" do
      expect(formatter.format(build(:work_package, created_at: timestamp))).to eq(timestamp.iso8601)
    end

    it "prints an empty string when missing" do
      expect(formatter.format(build(:work_package, created_at: nil))).to eq("")
    end
  end

  describe "updated_at" do
    subject(:formatter) { described_class.new(:updated_at) }

    it "prints the ISO timestamp" do
      expect(formatter.format(build(:work_package, updated_at: timestamp))).to eq(timestamp.iso8601)
    end
  end

  it { expect(Exports::Register.formatter_for(WorkPackage, :created_at, :md)).to be_a(described_class) }
  it { expect(Exports::Register.formatter_for(WorkPackage, :updated_at, :md)).to be_a(described_class) }
  it { expect(Exports::Register.formatter_for(WorkPackage, :created_at, :csv)).not_to be_a(described_class) }
end
