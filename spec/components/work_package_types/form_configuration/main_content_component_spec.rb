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

RSpec.describe WorkPackageTypes::FormConfiguration::MainContentComponent, type: :component do
  include_context "with a form configuration editor context"

  def render_main = render_inline(described_class.new(context: editor_context, group_components: [], ee_available: true))

  it "renders Reset and Add actions in editable EE mode", :aggregate_failures do
    render_main

    expect(page).to have_test_selector("type-form-configuration-reset-button")
    expect(page).to have_test_selector("type-form-configuration-add-button")
  end

  context "when read-only" do
    let(:readonly) { true }

    it "omits Reset, Add, and drag targets", :aggregate_failures do
      render_main

      expect(page).to have_no_test_selector("type-form-configuration-reset-button")
      expect(page).to have_no_test_selector("type-form-configuration-add-button")
      expect(page).to have_no_css("[data-controller*='sortable-lists']")
      expect(page).to have_test_selector("type-form-configuration-groups-container")
    end
  end

  describe "the groups container" do
    subject(:rendered_component) { render_main }

    it_behaves_like "a sortable-lists list", list_type: "group", name: nil
  end
end
