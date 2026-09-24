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
  subject(:contract) { described_class.new }

  let(:custom_field) { create(:list_wp_custom_field, possible_values: %w[Top Other]) }
  let(:root) { custom_field.hierarchy_root }
  let(:top) { root.children.find_by!(label: "Top") }

  it "accepts renaming an item directly under the root" do
    expect(contract.call(item: top, label: "Renamed")).to be_success
  end

  it "drops a short, which list items do not carry" do
    expect(contract.call(item: top, label: "Renamed", short: "RE").to_h).not_to have_key(:short)
  end

  it "rejects the root item" do
    result = contract.call(item: root, label: "Renamed")

    expect(result.errors[:item]).to include("cannot be a root item.")
  end

  it "rejects an item nested under another item" do
    nested = top.children.create!(label: "Nested")

    result = contract.call(item: nested, label: "Renamed")

    expect(result.errors[:item]).to include("cannot have sub-items for this custom field.")
  end

  it "rejects a label already used by a sibling" do
    result = contract.call(item: top, label: "Other")

    expect(result.errors[:label]).to include("must be unique within the same hierarchy level.")
  end
end
