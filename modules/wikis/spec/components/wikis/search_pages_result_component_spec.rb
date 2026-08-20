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

RSpec.describe Wikis::SearchPagesResultComponent, type: :component do
  subject do
    render_inline(described_class.new(tree_nodes, builder:, form_name: "wiki_page_selection", wikis_selectable:))
    page
  end

  let(:builder) { ActionView::Helpers::FormBuilder.new("", nil, vc_test_controller.view_context, {}) }
  let(:wikis_selectable) { false }

  let(:page_node) do
    Wikis::Adapters::Results::PageSearchTreeNode.page("42", "A page")
  end
  let(:wiki_node) do
    wiki_node = Wikis::Adapters::Results::PageSearchTreeNode.wiki("1", "A wiki")
    wiki_node.find_or_add_child(page_node)
    wiki_node
  end
  let(:tree_nodes) { [wiki_node] }

  it "identifies every node by its type and identifier" do
    expect(subject).to have_css("[data-node-id='wiki:1']")
    expect(subject).to have_css("[data-node-id='page:42']")
  end

  it "does not allow selecting the wiki" do
    expect(subject).to have_css("[data-node-id='wiki:1'][aria-disabled='true']")
  end

  it "allows selecting the page" do
    expect(subject).to have_no_css("[data-node-id='page:42'][aria-disabled='true']")
  end

  context "when wikis are selectable" do
    let(:wikis_selectable) { true }

    it "allows selecting the wiki" do
      expect(subject).to have_no_css("[data-node-id='wiki:1'][aria-disabled='true']")
    end
  end
end
