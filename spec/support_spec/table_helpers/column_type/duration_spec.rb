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

module TableHelpers::ColumnType
  RSpec.describe Duration do
    subject(:column_type) { described_class.new }

    describe "#parse" do
      it "parses empty string as nil" do
        expect(column_type.parse("")).to be_nil
      end
    end

    describe "#format" do
      it 'renders the duration with a "h" suffix' do
        expect(column_type.format(3.5)).to eq "3.5h"
      end

      it "renders the duration without the decimal part if the decimal part is 0" do
        expect(column_type.format(3.0)).to eq "3h"
      end

      it "renders nothing if nil" do
        expect(column_type.format(nil)).to eq ""
      end
    end

    describe "#cell_format" do
      it "renders the duration on the right side of the cell" do
        expect(column_type.cell_format(3.5, 0)).to eq "3.5h"
        expect(column_type.cell_format(3.5, 10)).to eq "      3.5h"
        expect(column_type.cell_format(3.5, 20)).to eq "                3.5h"
      end
    end
  end
end
