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

RSpec.describe WorkPackageRelationsTab::IndexComponent, type: :component do
  create_shared_association_defaults_for_work_package_factory

  shared_let(:user) { create(:admin) }
  shared_let(:work_package) { create(:work_package) }

  current_user { user }

  def render_component(**params)
    render_inline(described_class.new(work_package:, **params))
    page
  end

  context "with no relations" do
    it "renders a message" do
      expect(render_component).to have_heading "No relations"
      expect(page).to have_text "This work package does not have any relations yet."
    end
  end

  context "with parent relation" do
    shared_let_work_packages(<<~TABLE)
      hierarchy      | MTWTFSS | scheduling mode |
      parent         | XX      | automatic       |
        work_package | XX      | manual          |
    TABLE

    it "renders the relations group with the parent work package in it" do
      expect(render_component).to have_test_selector("op-relation-group-parent")
      expect(render_component).to have_list "Parent"

      list = page.find(:list, "Parent")
      expect(list).to have_list_item count: 1, text: /parent/
    end
  end

  context "with child relations" do
    shared_let_work_packages(<<~TABLE)
      hierarchy      | MTWTFSS | scheduling mode |
      work_package   |       X | automatic       |
        child1       | XXX     | manual          |
        child2       |         | automatic       |
    TABLE

    it "renders the relations group" do
      expect(render_component).to have_test_selector("op-relation-group-child")
    end

    it "renders the relations in child creation order" do
      expect(render_component).to have_list "Children"

      list = page.find(:list, "Children")
      expect(list).to have_list_item count: 2, text: /child\d/
      expect(list).to have_list_item position: 1, text: "child1"
      expect(list).to have_list_item position: 2, text: "child2"
    end
  end

  context "with follows relations" do
    shared_let_work_packages(<<~TABLE)
      hierarchy    | MTWTFSS    | scheduling mode | predecessors
      predecessor1 | XXX        | manual          |
      predecessor2 | XX         | manual          |
      predecessor3 | XX         | manual          |
      predecessor4 |            | manual          |
      work_package |          X | automatic       | predecessor1 with lag 2, predecessor2 with lag 7, predecessor3 with lag 7, predecessor4 with lag 10
    TABLE

    it "renders the relations group" do
      expect(render_component).to have_test_selector("op-relation-group-follows")
    end

    it "renders the relations in relation creation order" do
      expect(render_component).to have_list "Predecessors (before)"

      list = page.find(:list, "Predecessors (before)")
      expect(list).to have_list_item count: 4, text: /predecessor\d/
      expect(list).to have_list_item position: 1, text: "predecessor1"
      expect(list).to have_list_item position: 2, text: "predecessor2"
      expect(list).to have_list_item position: 3, text: "predecessor3"
      expect(list).to have_list_item position: 4, text: "predecessor4"

      # delete and recreate relation to predecessor2.
      relation_attributes = predecessor2.relations.first.attributes
      predecessor2.relations.first.destroy
      Relation.create!(relation_attributes.without("id"))

      # predecessor2 should now be at last position
      render_component
      list = page.find(:list, "Predecessors (before)")
      expect(list).to have_list_item position: 1, text: "predecessor1"
      expect(list).to have_list_item position: 2, text: "predecessor3"
      expect(list).to have_list_item position: 3, text: "predecessor4"
      expect(list).to have_list_item position: 4, text: "predecessor2"
    end

    it "renders the closest relation" do
      render_component

      list_item = page.find(:list_item, text: "predecessor2")
      expect(list_item).to have_primer_label("Closest")
    end
  end
end
