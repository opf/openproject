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

require "rails_helper"

RSpec.describe Forums::TableComponent, type: :component do
  subject(:rendered_component) do
    with_request_url("/projects/#{project.identifier}/forums") do
      render_inline(described_class.new(rows: project.forums, project:))
    end
  end

  shared_let(:project) { create(:project) }

  current_user { create(:user, member_with_permissions: { project => permissions }) }

  let(:permissions) { %i[view_messages manage_forums] }

  context "with forums" do
    shared_let(:general) { create(:forum, project:, name: "General", description: "Everything else") }

    it "captions the columns", :aggregate_failures do
      expect(rendered_component).to have_css(".Box-header", text: "Forum")
      expect(rendered_component).to have_css(".Box-header", text: "Topics")
      expect(rendered_component).to have_css(".Box-header", text: "Messages")
      expect(rendered_component).to have_css(".Box-header", text: "Last message")
    end

    it "offers row actions to forum managers" do
      expect(rendered_component).to have_test_selector("forum-action-menu")
    end

    it "wires a sortable list accepting forums" do
      expect(rendered_component).to have_css("#forums-table[data-controller='sortable-lists sortable-lists--list']") do |box|
        expect(box["data-sortable-lists--list-type-value"]).to eq("forum")
        expect(box["data-sortable-lists--list-accepted-type-value"]).to eq("forum")
        expect(box["data-sortable-lists--list-name-value"]).to eq("Forums")
        expect(box["data-sortable-lists-move-url-template-value"])
          .to eq("/projects/#{project.identifier}/forums/{id}/move")
        expect(box["data-sortable-lists--list-rows-container-element"]).to eq(":scope > .op-border-box-table--rows")
      end
    end

    it_behaves_like "a Border Box Table sortable list", row_count: 1

    it_behaves_like "sortable-lists items", list_type: "forum" do
      let(:sortable_records) { [general] }
    end

    context "without the manage forums permission" do
      let(:permissions) { %i[view_messages] }

      it "offers no row actions" do
        expect(rendered_component).to have_no_test_selector("forum-action-menu")
      end

      it "wires no sortable list" do
        expect(rendered_component).to have_no_css("[data-controller*='sortable-lists']")
      end
    end
  end

  context "without forums" do
    it "shows the blank slate" do
      expect(rendered_component).to have_text("There are currently no forums.")
    end
  end
end
