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

RSpec.describe Admin::CustomFields::Hierarchy::ItemComponent, type: :component do
  let(:custom_field_traits) { [:list, { possible_values: %w[Only Other] }] }
  let(:item) { custom_field.hierarchy_root.children.first }

  before { render_inline(described_class.new(item:, custom_field:)) }

  for_each_context(*CustomFieldAdminAreas::CONTEXTS) do
    it "links the item label into its own admin area" do
      expect(page).to have_link(item.label, href: "#{items_path}/#{item.id}")
    end

    it "loads the item's actions menu from its own admin area" do
      expect(page.find("include-fragment", visible: false)["src"]).to eq("#{items_path}/#{item.id}/item_actions")
    end
  end
end
