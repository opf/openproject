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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"
require_module_spec_helper

RSpec.describe Wikis::WikiPages::SidemenuTreeService do
  subject(:tree) do
    described_class.new(
      wiki:,
      current_page:,
      query:,
      href_resolver:
    ).nodes
  end

  shared_let(:admin) { create(:admin) }
  shared_let(:project) { create(:project, :with_internal_wiki).reload }
  shared_let(:wiki) { project.wiki }
  shared_let(:user) do
    create(:user, member_with_permissions: { project => %i[view_project view_wiki_pages] })
  end

  let!(:parent_page) { create(:wiki_page, wiki:, title: "Parent page", author: admin) }
  let!(:child_page) { create(:wiki_page, wiki:, title: "Unique child page", parent: parent_page, author: admin) }
  let!(:grandchild_page) { create(:wiki_page, wiki:, title: "Grandchild page", parent: child_page, author: admin) }
  let!(:sibling_page) { create(:wiki_page, wiki:, title: "Sibling page", author: admin) }

  let(:current_page) { nil }
  let(:query) { "" }
  let(:href_resolver) { ->(page) { "/wiki/#{page.slug}" } }

  current_user { user }

  it "builds all nodes collapsed by default" do
    parent = node_named(tree, "Parent page")
    sibling = node_named(tree, "Sibling page")

    expect(tree.map(&:label)).to contain_exactly("Parent page", "Sibling page")
    expect(parent).not_to be_expanded
    expect(parent.children.map(&:label)).to contain_exactly("Unique child page")
    expect(sibling).not_to be_expanded
    expect(tree).to all(satisfy { |node| !node.disabled? })
  end

  context "with a current page" do
    let(:current_page) { child_page }

    it "expands the current page and its ancestors" do
      parent = node_named(tree, "Parent page")
      child = node_named(parent.children, "Unique child page")
      grandchild = node_named(child.children, "Grandchild page")

      expect(parent).to be_expanded
      expect(child).to be_current
      expect(child).to be_expanded
      expect(grandchild).not_to be_expanded
    end
  end

  context "with a query" do
    let(:query) { "Unique" }

    it "keeps matching nodes and their ancestors" do
      parent = node_named(tree, "Parent page")
      child = node_named(parent.children, "Unique child page")

      expect(tree.map(&:label)).to contain_exactly("Parent page")
      expect(parent).to be_disabled
      expect(parent).to be_expanded
      expect(child).not_to be_disabled
      expect(child).to be_expanded
      expect(child.children).to be_empty
    end
  end

  context "with a user without permission to view wiki pages" do
    current_user { create(:user, member_with_permissions: { project => %i[view_project] }) }

    it "builds an empty tree" do
      expect(tree).to be_empty
    end
  end

  def node_named(nodes, label)
    nodes.find { |node| node.label == label }
  end
end
