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

RSpec.describe Admin::CustomFields::Hierarchy::TreeViewComponent,
               type: :component, with_ee: [:custom_field_hierarchies] do
  let!(:item) do
    CustomFields::Hierarchy::HierarchicalItemService
      .new
      .insert_item(contract_class: CustomFields::Hierarchy::InsertHierarchyItemContract,
                   parent: custom_field.hierarchy_root, label: "Branch")
      .value!
  end

  before { render_inline(described_class.new(custom_field:, active_item: custom_field.hierarchy_root)) }

  shared_examples "linking under" do |base|
    it "links each item under #{base}" do
      expect(page).to have_link("Branch", href: "#{base}/#{custom_field.id}/items/#{item.id}")
    end
  end

  context "for a work package custom field" do
    let(:custom_field) { create(:hierarchy_wp_custom_field) }

    it_behaves_like "linking under", "/custom_fields"
  end

  context "for a project custom field" do
    let(:custom_field) { create(:hierarchy_project_custom_field) }

    it_behaves_like "linking under", "/admin/settings/project_custom_fields"
  end

  context "for a user custom field" do
    let(:custom_field) { create(:user_custom_field, :hierarchy) }

    it_behaves_like "linking under", "/admin/settings/user_custom_fields"
  end
end
