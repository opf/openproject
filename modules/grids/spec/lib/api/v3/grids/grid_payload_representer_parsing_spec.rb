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

RSpec.describe API::V3::Grids::GridPayloadRepresenter, "parsing" do
  include API::V3::Utilities::PathHelper

  let(:object) do
    OpenStruct.new
  end
  let(:user) { build_stubbed(:user) }
  let(:representer) do
    described_class.create(object, current_user: user, embed_links: true)
  end

  let(:hash) do
    {
      "rowCount" => 10,
      "columnCount" => 20,
      "widgets" => [
        {
          _type: "Widget",
          identifier: "work_packages_assigned",
          startRow: 4,
          endRow: 5,
          startColumn: 1,
          endColumn: 2
        },
        {
          _type: "Widget",
          identifier: "work_packages_created",
          startRow: 1,
          endRow: 2,
          startColumn: 1,
          endColumn: 2
        },
        {
          _type: "Widget",
          identifier: "work_packages_watched",
          startRow: 2,
          endRow: 4,
          startColumn: 4,
          endColumn: 5
        }
      ],
      "_links" => {
        "scope" => {
          "href" => "some_path"
        }
      }
    }
  end

  describe "_links" do
    context "scope" do
      it "updates page" do
        grid = representer.from_hash(hash)
        expect(grid.scope)
          .to eql("some_path")
      end
    end
  end

  describe "properties" do
    context "rowCount" do
      it "updates row_count" do
        grid = representer.from_hash(hash)
        expect(grid.row_count)
          .to be(10)
      end
    end

    context "columnCount" do
      it "updates column_count" do
        grid = representer.from_hash(hash)
        expect(grid.column_count)
          .to be(20)
      end
    end

    context "widgets" do
      it "updates widgets" do
        grid = representer.from_hash(hash)

        expect(grid.widgets[0].identifier)
          .to eql("work_packages_assigned")
        expect(grid.widgets[0].start_row)
          .to be(4)
        expect(grid.widgets[0].end_row)
          .to be(5)
        expect(grid.widgets[0].start_column)
          .to be(1)
        expect(grid.widgets[0].end_column)
          .to be(2)

        expect(grid.widgets[1].identifier)
          .to eql("work_packages_created")
        expect(grid.widgets[1].start_row)
          .to be(1)
        expect(grid.widgets[1].end_row)
          .to be(2)
        expect(grid.widgets[1].start_column)
          .to be(1)
        expect(grid.widgets[1].end_column)
          .to be(2)

        expect(grid.widgets[2].identifier)
          .to eql("work_packages_watched")
        expect(grid.widgets[2].start_row)
          .to be(2)
        expect(grid.widgets[2].end_row)
          .to be(4)
        expect(grid.widgets[2].start_column)
          .to be(4)
        expect(grid.widgets[2].end_column)
          .to be(5)
      end
    end
  end
end
