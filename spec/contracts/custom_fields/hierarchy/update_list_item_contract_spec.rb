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

RSpec.describe CustomFields::Hierarchy::UpdateListItemContract do
  subject(:result) { described_class.new.call(params) }

  let(:custom_field) { create(:list_wp_custom_field, possible_values: %w[Top Other]) }
  let(:root) { custom_field.hierarchy_root }
  let(:top) { root.children.find_by!(label: "Top") }

  context "when renaming an item directly under the root" do
    let(:params) { { item: top, label: "Renamed", short: "RE" } }

    it { is_expected.to be_success }
    it("drops the short, which list items do not carry") { expect(result.to_h).not_to have_key(:short) }
  end

  context "when renaming the root" do
    let(:params) { { item: root, label: "Renamed" } }

    it("rejects the root") { expect(result.errors[:item]).to include("cannot be a root item.") }
  end

  context "when renaming an item nested below another one" do
    let(:params) { { item: top.children.create!(label: "Nested"), label: "Renamed" } }

    it("rejects the nesting") { expect(result.errors[:item]).to include("cannot have sub-items for this custom field.") }
  end

  context "when taking a label a sibling already uses" do
    let(:params) { { item: top, label: "Other" } }

    it("rejects the label") { expect(result.errors[:label]).to include("must be unique within the same hierarchy level.") }
  end
end
