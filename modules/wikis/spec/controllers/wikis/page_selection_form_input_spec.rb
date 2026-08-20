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

RSpec.describe Wikis::PageSelectionFormInput do
  subject(:consumer) { Class.new { include Wikis::PageSelectionFormInput }.new }

  let(:wiki_page_selection) { [{ path: ["A wiki", "A page"], nodeId: node_id }.to_json] }
  let(:node_id) { "page:42" }

  describe "#parse_selected_node" do
    subject { consumer.parse_selected_node(wiki_page_selection) }

    it { is_expected.to eq(Wikis::Adapters::Results::PageSearchTreeNode::NodeKey.new(type: :page, identifier: "42")) }

    context "when a wiki is selected" do
      let(:node_id) { "wiki:7" }

      it { is_expected.to eq(Wikis::Adapters::Results::PageSearchTreeNode::NodeKey.new(type: :wiki, identifier: "7")) }
    end

    context "when the opaque identifier contains colons itself" do
      let(:node_id) { "page:xwiki:VCR.Incredible space.WebHome" }

      it "keeps the identifier intact" do
        expect(subject.identifier).to eq("xwiki:VCR.Incredible space.WebHome")
      end
    end

    context "when the node type is unknown" do
      let(:node_id) { "project:42" }

      it { is_expected.to be_nil }
    end

    context "when nothing is selected" do
      let(:wiki_page_selection) { nil }

      it { is_expected.to be_nil }
    end

    context "when the payload carries no node id" do
      let(:wiki_page_selection) { [{ path: ["A wiki"] }.to_json] }

      it { is_expected.to be_nil }
    end
  end

  describe "#parse_page_identifier" do
    subject { consumer.parse_page_identifier(wiki_page_selection) }

    it { is_expected.to eq("42") }

    context "when a wiki is selected" do
      let(:node_id) { "wiki:7" }

      it "returns nothing, because a wiki can not be linked to" do
        expect(subject).to be_nil
      end
    end
  end
end
