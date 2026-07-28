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

RSpec.describe Projects::Settings::WorkPackages::Types::AddDialogComponent,
               type: :component,
               with_flag: { type_variants: true } do
  shared_let(:epic) { create(:type, name: "Epic") }
  shared_let(:design) { create(:type, name: "Design", parent: epic) }
  shared_let(:bug) { create(:type, name: "Bug") }

  subject(:component) { described_class.new(project:) }

  # The decorated autocompleter is an Angular custom element: its choices ride
  # along as JSON in data-items rather than as <option> tags.
  def offered_items
    JSON.parse(page.find("opce-autocompleter", visible: :all)["data-items"])
  end

  context "when one family is already active" do
    let(:project) { create(:project, types: [bug]) }

    before { render_inline(component) }

    it "offers the members of families that have none active" do
      expect(offered_items.pluck("id")).to contain_exactly(epic.id, design.id)
    end

    it "labels a variant with its composite name" do
      expect(offered_items.pluck("name")).to include("Epic: Design")
    end

    it "omits every member of the already-active family" do
      expect(offered_items.pluck("id")).not_to include(bug.id)
    end
  end

  context "when a variant is active" do
    let(:project) { create(:project, types: [design]) }

    before { render_inline(component) }

    it "omits the parent and its siblings" do
      expect(offered_items.pluck("id")).not_to include(epic.id, design.id)
    end

    it "still offers unrelated families" do
      expect(offered_items.pluck("id")).to include(bug.id)
    end
  end

  context "when every family already has an active member" do
    let(:project) { create(:project, types: [design, bug]) }

    before { render_inline(component) }

    it "explains there is nothing to add instead of rendering the field" do
      expect(page).to have_text("All available types are already active in this project")
      expect(page).to have_no_css("opce-autocompleter", visible: :all)
    end
  end
end
