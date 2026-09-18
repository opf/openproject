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

RSpec.describe Admin::Enumerations::IndexComponent, type: :component do
  subject(:rendered_component) do
    with_request_url("/admin/settings/work_package_priorities") do
      render_inline(described_class.new(enumerations:))
    end
  end

  context "with enumerations" do
    let!(:priority_a) { create(:priority, name: "Urgent") }
    let!(:priority_b) { create(:priority, name: "Trivial") }
    let(:enumerations) { IssuePriority.where(id: [priority_a.id, priority_b.id]).order(:position) }

    it_behaves_like "rendering Box", row_count: 2
    it_behaves_like "rendering Border Box List heading",
                    text: IssuePriority.model_name.human(count: :other),
                    level: 3

    it "renders a row per enumeration", :aggregate_failures do
      expect(rendered_component).to have_css(".Box-row", text: "Urgent")
      expect(rendered_component).to have_css(".Box-row", text: "Trivial")
    end

    it "wires the wrapper as the sortable-lists root", :aggregate_failures do
      root = rendered_component.at_css("#admin-enumerations-index-component")

      expect(root["data-controller"]).to eq("sortable-lists")
      expect(root["data-sortable-lists-move-url-template-value"])
        .to eq("/admin/settings/work_package_priorities/{id}/move")
      expect(root["data-sortable-lists-sortable-lists--list-outlet"])
        .to eq("#admin-enumerations-index-component [data-controller~='sortable-lists--list']")
      expect(root["data-sortable-lists-sortable-lists--item-outlet"])
        .to eq("#admin-enumerations-index-component [data-controller~='sortable-lists--item']")
    end

    it "wires the box as the sortable list", :aggregate_failures do
      list = rendered_component.at_css("[data-controller~='sortable-lists--list']")

      expect(list["data-sortable-lists--list-type-value"]).to eq("issue_priority")
      expect(list["data-sortable-lists--list-accepted-type-value"]).to eq("issue_priority")
      expect(list["data-sortable-lists--list-name-value"])
        .to eq(IssuePriority.model_name.human(count: :other))
    end

    # The list controller's default rows container is `:scope > ul`; Primer's
    # BorderBox renders its rows into exactly that, so no override is needed.
    it "keeps the rows in the list controller's default rows container" do
      expect(rendered_component)
        .to have_css("[data-controller~='sortable-lists--list'] > ul.Box-list > li.Box-row", count: 2)
    end

    it "does not override the rows container selector" do
      expect(rendered_component)
        .to have_no_css("[data-sortable-lists--list-rows-container-element]")
    end

    it "wires every row as a sortable item", :aggregate_failures do
      [priority_a, priority_b].each do |priority|
        row = rendered_component.at_css(".Box-row[data-sortable-lists--item-id-value='#{priority.id}']")

        expect(row["data-controller"]).to eq("sortable-lists--item")
        expect(row["data-sortable-lists--item-type-value"]).to eq("issue_priority")
        expect(row["data-sortable-lists--item-label-value"]).to eq(priority.name)
      end
    end

    it "no longer wires the legacy drag-and-drop controller", :aggregate_failures do
      expect(rendered_component).to have_no_css("[data-controller~='generic-drag-and-drop']")
      expect(rendered_component).to have_no_css("[data-generic-drag-and-drop-target]")
      expect(rendered_component).to have_no_css("[data-drop-url]")
    end
  end

  context "without enumerations" do
    let(:enumerations) { IssuePriority.where(id: nil) }

    it_behaves_like "rendering an empty Border Box List", heading: I18n.t(:no_results_title_text)
  end
end
