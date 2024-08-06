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

module TableHelpers
  RSpec.describe TableRepresenter do
    let(:table) do
      <<~TABLE
        | subject      | remaining work | derived remaining work |
        | Work Package |           1.5h |                     9h |
      TABLE
    end
    let(:table_data) { TableData.for(table) }
    let(:tables_data) { [table_data] }

    subject(:representer) { described_class.new(tables_data:, columns:) }

    context "when using a second table for the size" do
      let(:twin_table) do
        <<~TABLE
          | subject                        |
          | A quite long work package name |
        TABLE
      end
      let(:twin_table_data) { TableData.for(twin_table) }

      let(:tables_data) { [table_data, twin_table_data] }
      let(:columns) { [Column.for("subject")] }

      it "adapts the column sizes to fit the largest value of both tables " \
         "so that they can be compared and diffed" do
        expect(representer.render(table_data)).to eq <<~TABLE
          | subject                        |
          | Work Package                   |
        TABLE
        expect(representer.render(twin_table_data)).to eq <<~TABLE
          | subject                        |
          | A quite long work package name |
        TABLE
      end
    end

    describe "subject column" do
      let(:columns) { [Column.for("subject")] }

      it "is rendered as text" do
        expect(representer.render(table_data)).to eq <<~TABLE
          | subject      |
          | Work Package |
        TABLE
      end
    end

    describe "remaining work column" do
      let(:columns) { [Column.for("remaining work")] }

      it "is rendered as a duration" do
        expect(representer.render(table_data)).to eq <<~TABLE
          | remaining work |
          |           1.5h |
        TABLE
      end
    end

    describe "derived remaining work column" do
      let(:columns) { [Column.for("derived remaining work")] }

      it "sets the derived remaining work attribute" do
        expect(representer.render(table_data)).to eq <<~TABLE
          | derived remaining work |
          |                     9h |
        TABLE
      end
    end
  end
end
