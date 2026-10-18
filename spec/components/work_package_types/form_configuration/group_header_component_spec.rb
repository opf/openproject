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
  let(:variant) { create(:type).default_variant }
  let(:group) { { key: "details", name: "Details", type: :attribute } }

  def editor_context(readonly: false, exclusions: nil)
    WorkPackageTypes::FormConfiguration::EditorContext.for_variant(variant, scope_project: nil).tap do |context|
      allow(context).to receive_messages(readonly?: readonly, exclusions:)
    end
  end

  def render_header(readonly:)
    render_inline(described_class.new(group:, context: editor_context(readonly:), ee_available: true, first: true,
                                      last: true, edit_mode: false))
  end

  it "renders the drag handle and actions menu in editable mode", :aggregate_failures do
    render_header(readonly: false)

    expect(page).to have_test_selector("type-form-configuration-group-handle-details")
    expect(page).to have_test_selector("type-form-configuration-group-actions-details")
    expect(page).to have_text("Details")
  end

  it "omits the handle and actions menu when readonly", :aggregate_failures do
    render_header(readonly: true)

    expect(page).to have_no_test_selector("type-form-configuration-group-handle-details")
    expect(page).to have_no_test_selector("type-form-configuration-group-actions-details")
    expect(page).to have_text("Details")
  end
end
