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

RSpec.describe OpenProject::Sidemenu::TreeComponent, type: :component do
  let(:great_grandchild) do
    OpenProject::Sidemenu::TreeNode.new(id: 4, label: "Great-grandchild page", href: "/great-grandchild")
  end
  let(:grandchild) do
    OpenProject::Sidemenu::TreeNode.new(
      id: 3,
      label: "Grandchild page",
      href: "/grandchild",
      children: [great_grandchild]
    )
  end
  let(:child) do
    OpenProject::Sidemenu::TreeNode.new(
      id: 2,
      label: "Child page",
      href: "/child",
      children: [grandchild],
      current: true,
      expanded: true,
      data: { test_selector: "wiki-sidemenu-tree--item" }
    )
  end
  let(:parent) do
    OpenProject::Sidemenu::TreeNode.new(
      id: 1,
      label: "Parent page",
      href: "/parent",
      children: [child],
      expanded: true
    )
  end

  it "renders tree nodes with their selection and expansion state" do
    render_inline(described_class.new(nodes: [parent]))

    expect(page).to have_css("tree-view")
    expect(page).to have_css(".TreeViewItemContent[aria-expanded='true']", text: "Parent page")
    expect(page).to have_css(".TreeViewItemContent[aria-current='true'][aria-expanded='true']", text: "Child page")
    expect(page).to have_css(".TreeViewItemContent[aria-expanded='false']", text: "Grandchild page")
    expect(page).to have_no_css(".TreeViewItemContent", text: "Great-grandchild page")
  end

  it "highlights query terms in node labels" do
    render_inline(described_class.new(nodes: [parent], query_terms: ["Child"]))

    expect(page).to have_css(".op-search-highlight", text: "Child")
  end
end
