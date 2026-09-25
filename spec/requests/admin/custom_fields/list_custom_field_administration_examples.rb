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

RSpec.shared_examples "list custom field administration" do |type, create_route:, redirect_route:, items_route:|
  let(:root) { custom_field.hierarchy_root }

  def entry(label) = root.children.find_by!(label:)

  def labels = root.reload.children.reorder(:sort_order).pluck(:label)

  define_method(:item_path) do |item, action = nil, **params|
    public_send([action, "#{items_route}_item_path"].compact.join("_"), custom_field, item, **params)
  end

  it "creates a list field with its root and opens its own admin page" do
    attributes = { name: "Operating system", field_format: "list", multi_value: "1", **create_attributes }
    post public_send(:"#{create_route}_path"), params: { type:, custom_field: attributes }

    created = CustomField.find_by!(name: "Operating system")
    expect(response).to redirect_to(public_send(:"#{redirect_route}_path", created))
    expect(created).to have_attributes(type:, multi_value: true)
    expect(created.hierarchy_root).to be_persisted
  end

  it "adds an entry at the requested position" do
    post item_path(root, :new_child), params: { label: "banana", sort_order: 1 }

    expect(labels).to eq %w[pear banana apple]
  end

  it "ignores a posted short name" do
    post item_path(root, :new_child), params: { label: "cherry", short: "CH" }

    expect(entry("cherry").short).to be_nil
  end

  it "refuses to nest an entry under another one" do
    post item_path(entry("pear"), :new_child), params: { label: "nested", sort_order: 0 }

    expect(entry("pear").children).to be_empty
  end

  it "renames an entry" do
    put item_path(entry("pear")), params: { label: "peach" }

    expect(labels).to eq %w[peach apple]
  end

  it "deletes an entry" do
    delete item_path(entry("pear"))

    expect(labels).to eq %w[apple]
  end

  it "moves an entry and returns to the list" do
    post item_path(entry("apple"), :move), params: { new_sort_order: 0 }

    expect(response).to redirect_to(item_path(root))
    expect(labels).to eq %w[apple pear]
  end

  it "sets and clears the default entry" do
    post item_path(entry("pear"), :set_default)
    expect(entry("pear")).to be_default_value

    post item_path(entry("pear"), :clear_default)
    expect(entry("pear")).not_to be_default_value
  end

  it "reorders the entries alphabetically" do
    post item_path(root, :reorder_alphabetical)

    expect(labels).to eq %w[apple pear]
  end
end
