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

RSpec.describe WorkPackageRelationsTab::AddWorkPackageHierarchyDialogComponent, type: :component do
  include Rails.application.routes.url_helpers

  let(:work_package) { build_stubbed(:work_package) }

  subject { described_class.new(work_package:, relation_type:) }

  context "when adding a child" do
    let(:relation_type) { Relation::TYPE_CHILD }

    it "displays the dialog with 'Add child' title" do
      render_inline(subject)

      expect(page).to have_text("Add child")
    end

    it "uses work package autocompleter with url having available_relation_candidates?type=child" do
      rendered = render_inline(subject)
      expect(rendered.to_html).to include("available_relation_candidates?type=child")
    end

    it "has relation_type=child as a parameter of the form action" do
      render_inline(subject)

      form = page.find("form")
      expect(form["action"]).to eq(work_package_hierarchy_relations_path(work_package, relation_type: "child"))
    end
  end

  context "when adding a parent" do
    let(:relation_type) { Relation::TYPE_PARENT }

    it "displays the dialog with 'Add parent' title" do
      render_inline(subject)

      expect(page).to have_text("Add parent")
    end

    it "uses work package autocompleter with url having available_relation_candidates?type=parent" do
      rendered = render_inline(subject)
      expect(rendered.to_html).to include("available_relation_candidates?type=parent")
    end

    it "has relation_type=parent as a parameter of the form action" do
      render_inline(subject)

      form = page.find("form")
      expect(form["action"]).to eq(work_package_hierarchy_relations_path(work_package, relation_type: "parent"))
    end
  end
end
