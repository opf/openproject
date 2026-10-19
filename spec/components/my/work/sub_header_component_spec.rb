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

RSpec.describe My::Work::SubHeaderComponent, type: :component do
  let(:date) { Date.new(2026, 10, 5) }
  let(:entries) { :all }

  subject(:rendered_component) do
    render_inline(described_class.new(date:, mode: :workweek, view_mode: :stack, entries:))
  end

  current_user { build_stubbed(:user) }

  context "with the resource management enterprise feature", with_ee: %i[resource_management] do
    it "offers to filter the entries" do
      expect(rendered_component).to have_css("#my-work-entries-filter-button", text: "All entries")
      expect(rendered_component).to have_link("Logged time only", href: /entries=logged/)
      expect(rendered_component).to have_link("Allocations only", href: /entries=allocated/)
    end

    it "places the filter after the mode switcher" do
      buttons = rendered_component.css("#my-work-mode-switch-button, #my-work-entries-filter-button").pluck("id")

      expect(buttons).to eq(%w[my-work-mode-switch-button my-work-entries-filter-button])
    end

    context "when filtered to allocations" do
      let(:entries) { :allocated }

      it "shows the filter that is applied" do
        expect(rendered_component).to have_css("#my-work-entries-filter-button", text: "Allocations only")
      end

      it "keeps the filter when moving to another week" do
        expect(rendered_component).to have_css("[data-test-selector='my-work-next'][href*='entries=allocated']")
      end
    end
  end

  context "without the resource management enterprise feature", with_ee: false do
    it "does not offer to filter the entries" do
      expect(rendered_component).to have_no_css("#my-work-entries-filter-button")
    end
  end
end
