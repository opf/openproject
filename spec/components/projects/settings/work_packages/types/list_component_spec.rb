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

RSpec.describe Projects::Settings::WorkPackages::Types::ListComponent,
               type: :component,
               with_flag: { type_variants: true } do
  include Rails.application.routes.url_helpers

  # acts_as_list overrides positions passed at creation, so pin them afterwards.
  shared_let(:epic) { create(:type, name: "Epic").tap { |type| type.update_column(:position, 1) } }
  shared_let(:bug) { create(:type, name: "Bug").tap { |type| type.update_column(:position, 2) } }
  shared_let(:design) { create(:type_variant, type: epic, variant_name: "Design") }

  subject(:component) { described_class.new(project:) }

  context "when a type is active through its base variant" do
    let(:project) { create(:project, types: [bug]) }

    before { render_inline(component) }

    it "names the type" do
      expect(page).to have_text("Bug")
    end

    it "offers the remove action" do
      expect(page).to have_button("Remove from project", visible: :all)
      expect(page).to have_css(
        "form[action='#{project_settings_work_packages_type_path(project, bug)}']",
        visible: :all
      )
    end
  end

  context "when a type is active through a named variant" do
    let(:project) { create(:project, types: [design]) }

    before { render_inline(component) }

    it "names the type, not the composite name" do
      expect(page).to have_text("Epic")
      expect(page).to have_no_text("Epic: Design")
    end

    # normalize_ws because render_inline keeps the newline between the two Text
    # components that a browser lays out on one line.
    it "names the active variant after the type it presents as" do
      expect(page).to have_text("Variant: Design", normalize_ws: true)
    end

    it "points the remove action at the type the variant belongs to" do
      expect(page).to have_css(
        "form[action='#{project_settings_work_packages_type_path(project, epic)}']",
        visible: :all
      )
    end
  end

  context "with several active types" do
    let(:project) { create(:project, types: [design, bug]) }

    before { render_inline(component) }

    it "orders rows by the type's position" do
      expect(page.all("[data-test-selector^='project-types-row-']").pluck(:"data-test-selector"))
        .to eq(["project-types-row-#{design.id}", "project-types-row-#{bug.default_variant.id}"])
    end
  end

  context "without any active type" do
    # The workspace factory pushes the standard type whenever types is empty.
    let(:project) { create(:project, types: [], no_types: true) }

    before { render_inline(component) }

    it "renders the empty state" do
      expect(page).to have_text("No types are active in this project")
    end
  end
end
