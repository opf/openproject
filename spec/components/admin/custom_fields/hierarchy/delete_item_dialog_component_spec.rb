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

RSpec.describe Admin::CustomFields::Hierarchy::DeleteItemDialogComponent, type: :component do
  let(:custom_field_traits) { [:list, { possible_values: %w[Only Other] }] }
  let(:item) { custom_field.hierarchy_root.children.first }

  subject(:rendered_dialog) { render_inline(described_class.new(custom_field:, hierarchy_item: item)) }

  for_each_context(*CustomFieldAdminAreas::CONTEXTS) do
    it "submits the deletion into its own admin area" do
      expect(rendered_dialog.at_css("form")["action"]).to eq("#{items_path}/#{item.id}")
    end
  end

  context "for a list field" do
    let(:custom_field) { create(:list_wp_custom_field, possible_values: %w[Only Other]) }

    it("does not warn about sub-items it cannot have") { is_expected.to have_no_text("sub-items") }
  end

  context "for a hierarchy field", with_ee: [:custom_field_hierarchies] do
    let(:custom_field) { create(:hierarchy_wp_custom_field) }
    let(:item) { create(:hierarchy_item, parent: custom_field.hierarchy_root) }

    it("warns that sub-items go too") { is_expected.to have_text("remove the item and all its sub-items") }
  end
end
