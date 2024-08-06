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

RSpec.describe API::V3::Grids::GridRepresenter, "rendering" do
  include OpenProject::StaticRouting::UrlHelpers
  include API::V3::Utilities::PathHelper

  let(:grid) do
    build_stubbed(
      :grid,
      row_count: 4,
      column_count: 5,
      widgets: [
        build_stubbed(
          :grid_widget,
          identifier: "work_packages_assigned",
          start_row: 4,
          end_row: 5,
          start_column: 1,
          end_column: 2
        ),
        build_stubbed(
          :grid_widget,
          identifier: "work_packages_created",
          start_row: 1,
          end_row: 2,
          start_column: 1,
          end_column: 2
        ),
        build_stubbed(
          :grid_widget,
          identifier: "work_packages_watched",
          start_row: 2,
          end_row: 4,
          start_column: 4,
          end_column: 5
        )
      ]
    )
  end

  let(:embed_links) { true }
  let(:current_user) { build_stubbed(:user) }
  let(:representer) { described_class.new(grid, current_user:, embed_links:) }

  let(:writable) { true }
  let(:scope_path) { "bogus_scope" }
  let(:attachment_addable) { true }

  before do
    OpenProject::Cache.clear

    allow(Grids::Configuration)
      .to receive(:writable?)
      .with(grid, current_user)
      .and_return(writable)

    allow(Grids::Configuration)
      .to receive(:to_scope)
      .with(Grids::Grid, [])
      .and_return(scope_path)

    allow(grid)
      .to receive(:attachments_addable?)
      .with(current_user)
      .and_return(attachment_addable)
  end

  context "generation" do
    subject(:generated) { representer.to_json }

    context "properties" do
      it "denotes its type" do
        expect(subject)
          .to be_json_eql("Grid".to_json)
          .at_path("_type")
      end

      it "has an id" do
        expect(subject)
          .to be_json_eql(grid.id)
          .at_path("id")
      end

      it "has a rowCount" do
        expect(subject)
          .to be_json_eql(4)
          .at_path("rowCount")
      end

      it "has a columnCount" do
        expect(subject)
          .to be_json_eql(5)
          .at_path("columnCount")
      end

      describe "createdAt" do
        it_behaves_like "has UTC ISO 8601 date and time" do
          let(:date) { grid.created_at }
          let(:json_path) { "createdAt" }
        end
      end

      describe "updatedAt" do
        it_behaves_like "has UTC ISO 8601 date and time" do
          let(:date) { grid.updated_at }
          let(:json_path) { "updatedAt" }
        end
      end

      it "has a list of widgets" do
        widgets = [
          {
            _type: "GridWidget",
            id: grid.widgets[0].id,
            identifier: "work_packages_assigned",
            options: {},
            startRow: 4,
            endRow: 5,
            startColumn: 1,
            endColumn: 2
          },
          {
            _type: "GridWidget",
            id: grid.widgets[1].id,
            identifier: "work_packages_created",
            options: {},
            startRow: 1,
            endRow: 2,
            startColumn: 1,
            endColumn: 2
          },
          {
            _type: "GridWidget",
            id: grid.widgets[2].id,
            identifier: "work_packages_watched",
            options: {},
            startRow: 2,
            endRow: 4,
            startColumn: 4,
            endColumn: 5
          }
        ]

        expect(subject)
          .to be_json_eql(widgets.to_json)
          .at_path("widgets")
      end
    end

    context "_links" do
      context "self link" do
        it_behaves_like "has an untitled link" do
          let(:link) { "self" }
          let(:href) { "/api/v3/grids/#{grid.id}" }
        end
      end

      context "update link" do
        it_behaves_like "has an untitled link" do
          let(:link) { "update" }
          let(:href) { "/api/v3/grids/#{grid.id}/form" }
          let(:method) { :post }
        end
      end

      context "updateImmediately link" do
        it_behaves_like "has an untitled link" do
          let(:link) { "updateImmediately" }
          let(:href) { "/api/v3/grids/#{grid.id}" }
          let(:method) { :patch }
        end
      end

      context "scope link" do
        it_behaves_like "has an untitled link" do
          let(:link) { "scope" }
          let(:href) { scope_path }
          let(:type) { "text/html" }

          it "has a content type of html" do
            expect(subject)
              .to be_json_eql(type.to_json)
              .at_path("_links/#{link}/type")
          end
        end
      end

      it_behaves_like "has an untitled link" do
        let(:link) { "attachments" }
        let(:href) { api_v3_paths.attachments_by_grid(grid.id) }
      end

      context "addAttachments link" do
        it_behaves_like "has an untitled link" do
          let(:link) { "addAttachment" }
          let(:href) { api_v3_paths.attachments_by_grid(grid.id) }
        end

        context "user is not allowed to edit work packages" do
          let(:attachment_addable) { false }

          it_behaves_like "has no link" do
            let(:link) { "addAttachment" }
          end
        end
      end
    end

    context "embedded" do
      it "embeds the attachments as collection" do
        expect(subject)
          .to be_json_eql("Collection".to_json)
          .at_path("_embedded/attachments/_type")
      end
    end
  end
end
