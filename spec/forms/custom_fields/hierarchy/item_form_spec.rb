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

# A list custom field on a UserCustomField or ProjectCustomField must send Cancel
# back into its own admin area, not the generic /custom_fields/... route that would
# throw the admin out of /admin/settings/user_custom_fields/... entirely.
RSpec.describe CustomFields::Hierarchy::ItemForm do
  def cancel_href_for(item)
    described_class.new(nil, target_item: item, secondary_input_format: nil).send(:cancel_href)
  end

  describe "for a user custom field" do
    let(:custom_field) { create(:user_custom_field, :list, possible_values: %w[Only Other]) }
    let(:item) { custom_field.hierarchy_root.children.first }

    it "cancels back to the user custom field admin area" do
      expect(cancel_href_for(item)).to include("/admin/settings/user_custom_fields/")
    end
  end

  describe "for a project custom field" do
    let(:custom_field) { create(:list_project_custom_field, possible_values: %w[Only Other]) }
    let(:item) { custom_field.hierarchy_root.children.first }

    it "cancels back to the project custom field admin area" do
      expect(cancel_href_for(item)).to include("/admin/settings/project_custom_fields/")
    end
  end

  describe "for a work package custom field" do
    let(:custom_field) { create(:list_wp_custom_field, possible_values: %w[Only Other]) }
    let(:item) { custom_field.hierarchy_root.children.first }

    it "cancels back to the generic custom field items route" do
      expect(cancel_href_for(item)).to match(%r{\A/custom_fields/})
    end
  end
end
