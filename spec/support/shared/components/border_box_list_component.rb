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

# Shared expectations for lists rendered through
# OpenProject::Common::BorderBoxListComponent.
#
# Asserts the heading is a real heading element rendered inside the
# +.Box-header+, not merely text that happens to appear somewhere.
RSpec.shared_examples_for "rendering Border Box List heading" do |text:, level: nil|
  it "renders Border Box List heading '#{text}'" do
    expect(rendered_component).to have_css(".Box-header") do |header|
      expect(header).to have_heading(text, **{ level: }.compact)
    end
  end
end

# Shared expectations for an itemless Border Box List: the component renders
# a single Blank Slate row in place of the list items.
RSpec.shared_examples_for "rendering an empty Border Box List" do |heading:, icon: nil, row_count: 1, header: true|
  it_behaves_like("rendering Box", row_count:, header:)
  it_behaves_like("rendering Blank Slate", heading:, icon:)
end

# Shared expectations for lists rendered through
# OpenProject::Common::BorderBoxListComponent with generic drag-and-drop
# reordering.
#
# Including contexts must pass +drag_type:+ and define the following:
#
# - +draggable_records+: ordered records expected to render as rows.
# - +drop_url_for(record)+: the value each row's +data-drop-url+ ends with.
# - +draggable_id_for(record)+: optional value for +data-draggable-id+.
#   Defaults to +record.id+.
RSpec.shared_examples_for "a reorderable Border Box List" do |drag_type:|
  it "renders a drag-and-drop enabled Border Box List container" do
    expect(rendered_component)
      .to have_css(".Box.op-border-box-list[data-generic-drag-and-drop-target='container']") do |box|
        expect(box["data-target-container-accessor"]).to eq(":scope > ul")
        expect(box["data-target-allowed-drag-type"]).to eq(drag_type)
      end
  end

  it "renders the expected number of draggable rows" do
    expect(rendered_component)
      .to have_css(".Box-row[data-draggable-type='#{drag_type}']", count: draggable_records.size)
  end

  it "renders each record as a draggable row pointing at its drop URL", :aggregate_failures do
    draggable_records.each do |record|
      draggable_id = respond_to?(:draggable_id_for) ? draggable_id_for(record) : record.id
      selector = ".Box-row[data-draggable-type='#{drag_type}'][data-draggable-id='#{draggable_id}']"

      expect(rendered_component).to have_css(selector) do |row|
        expect(row["data-drop-url"]).to end_with(drop_url_for(record))
      end
    end
  end
end
