# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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

module TableHelpers::ColumnType
  RSpec.describe Percentage do
    subject(:column_type) { described_class.new }

    describe "#parse" do
      it "parses empty string as nil" do
        expect(column_type.parse("")).to be_nil
      end
    end

    describe "#format" do
      it 'renders the percentage with a "%" suffix' do
        expect(column_type.format(30)).to eq "30%"
        expect(column_type.format(30.9)).to eq "30%"
      end

      it "renders nothing if nil" do
        expect(column_type.format(nil)).to eq ""
      end
    end

    describe "#cell_format" do
      it "renders the percentage on the right side of the cell" do
        expect(column_type.cell_format(20, 0)).to eq "20%"
        expect(column_type.cell_format(35, 10)).to eq "       35%"
        expect(column_type.cell_format(57, 20)).to eq "                 57%"
      end
    end
  end
end
