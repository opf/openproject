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

RSpec.describe Settings::UserCustomFieldSections::ShowComponent, type: :component do
  let(:section) { create(:user_custom_field_section, attribute_order: ["login"]) }
  let(:field_a) { create(:user_custom_field, user_custom_field_section: section) }
  let(:field_b) { create(:user_custom_field, user_custom_field_section: section) }

  subject do
    with_request_url "/admin/settings/user_custom_fields" do
      # custom_fields_by_key/attribute_order read the section's in-memory
      # state, which the fields' after_create_commit callback updates via a
      # separate `section` instance in the association chain, so this
      # `let`-bound object must be reloaded to see it.
      render_inline(described_class.new(user_custom_field_section: section.reload))
    end
  end

  before do
    field_a
    field_b
  end

  it "wires the section-header drag handle as the sortable-lists item handle target" do
    subject

    expect(page).to have_css(
      ".Box-header .handle[data-sortable-lists--item-target='handle']",
      count: 1
    )
  end
end
