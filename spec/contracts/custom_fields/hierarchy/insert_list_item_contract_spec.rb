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

RSpec.describe CustomFields::Hierarchy::InsertListItemContract do
  subject(:contract) { described_class.new }

  let(:custom_field) { create(:list_wp_custom_field, possible_values: %w[Top Other]) }
  let(:root) { custom_field.hierarchy_root }
  let(:top) { root.children.find_by!(label: "Top") }

  it "accepts an item directly under the root" do
    expect(contract.call(parent: root, label: "Sibling")).to be_success
  end

  it "drops a short, which list items do not carry" do
    expect(contract.call(parent: root, label: "Sibling", short: "SI").to_h).not_to have_key(:short)
  end

  it "rejects an item under another item" do
    result = contract.call(parent: top, label: "Nested")

    expect(result.errors[:parent]).to include("cannot have sub-items for this custom field.")
  end

  it "rejects a label already used by a sibling" do
    result = contract.call(parent: root, label: "Top")

    expect(result.errors[:label]).to include("must be unique within the same hierarchy level.")
  end
end
