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

require "rails_helper"

RSpec.describe WorkPackageTypes::FormConfiguration::GroupHeaderComponent, type: :component do
  include_context "with a form configuration editor context"

  let(:group) { { key: "details", name: "Details", type: :attribute } }

  def render_header(first: true, last: true)
    render_inline(described_class.new(group:, context: editor_context, ee_available: true, first:, last:,
                                      edit_mode: false))
  end

  it "renders the drag handle and actions menu in editable mode", :aggregate_failures do
    render_header

    expect(page).to have_test_selector("type-form-configuration-group-handle-details")
    expect(page).to have_test_selector("type-form-configuration-group-actions-details")
    expect(page).to have_text("Details")
  end

  context "when read-only" do
    let(:readonly) { true }

    it "omits the handle and actions menu", :aggregate_failures do
      render_header

      expect(page).to have_no_test_selector("type-form-configuration-group-handle-details")
      expect(page).to have_no_test_selector("type-form-configuration-group-actions-details")
      expect(page).to have_text("Details")
    end
  end

  it_behaves_like "offers the shared move items" do
    let(:rendered_component) { render_header(first: false, last: false) }
  end

  it_behaves_like "offers no move items" do
    let(:rendered_component) { render_header(first: true, last: true) }
  end
end
