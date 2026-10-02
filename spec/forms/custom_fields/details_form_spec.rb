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

RSpec.describe CustomFields::DetailsForm, type: :forms do
  include ViewComponent::TestHelpers

  current_user { build_stubbed(:admin) }

  def render_form
    render_in_view_context(custom_field) do |custom_field|
      primer_form_with(url: "/foo", model: custom_field, scope: :custom_field) do |f|
        render(CustomFields::DetailsForm.new(f))
      end
    end
  end

  before do
    render_form
  end

  context "for a list custom field" do
    let(:custom_field) { build_stubbed(:list_wp_custom_field, display_as: "radio_buttons") }

    it "renders the 'Display as' select with the current choice" do
      expect(page).to have_select "Display as",
                                  options: ["Dropdown", "Checkboxes (multi-select only)",
                                            "Radio buttons (single-select only)"],
                                  selected: "Radio buttons (single-select only)"
    end
  end

  context "for a list custom field without a choice" do
    let(:custom_field) { build_stubbed(:list_wp_custom_field) }

    it "preselects the dropdown" do
      expect(page).to have_select "Display as", selected: "Dropdown"
    end
  end

  context "for a string custom field" do
    let(:custom_field) { build_stubbed(:string_wp_custom_field) }

    it "does not render the 'Display as' select" do
      expect(page).to have_no_select "Display as"
    end
  end
end
