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

# Shared expectations for admin lists rendered through
# OpenProject::Common::BorderBoxListComponent with generic drag-and-drop
# reordering.
#
# Including contexts must define the following:
#
# - +draggable_records+: ordered records expected to render as rows.
# - +row_test_selector_prefix+: prefix joined with the record id to form each
#   row's +data-test-selector+.
# - +move_path_base+: path the per-row +data-drop-url+ ends with, before
#   +/<id>/move+.
RSpec.shared_examples_for "a reorderable Border Box List" do |drag_type: "enumeration"|
  it "renders a drag-and-drop enabled Border Box List container", :aggregate_failures do
    expect(rendered_component).to have_css(".Box.op-border-box-list")
    expect(rendered_component).to have_css(".Box[data-generic-drag-and-drop-target='container']")
    expect(rendered_component).to have_css(".Box[data-target-container-accessor=':scope > ul']")
    expect(rendered_component).to have_css(".Box[data-target-allowed-drag-type='#{drag_type}']")
  end

  it "renders each record as a draggable row", :aggregate_failures do
    expect(rendered_component)
      .to have_css(".Box-row[data-draggable-type='#{drag_type}']", count: draggable_records.size)

    draggable_records.each do |record|
      expect(rendered_component).to have_css(
        ".Box-row[data-test-selector='#{row_test_selector_prefix}#{record.id}']" \
        "[data-draggable-id='#{record.id}']" \
        "[data-draggable-type='#{drag_type}']" \
        "[data-drop-url$='#{move_path_base}/#{record.id}/move']",
        text: record.name
      )
    end
  end
end
