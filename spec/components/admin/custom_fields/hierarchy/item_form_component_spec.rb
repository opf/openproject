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

RSpec.describe Admin::CustomFields::Hierarchy::ItemFormComponent, type: :component do
  describe "#secondary_input_format" do
    def item_for(custom_field)
      custom_field.hierarchy_root.children.build(label: "Stormtroopers")
    end

    it "is :short for a hierarchy field", with_ee: [:custom_field_hierarchies] do
      custom_field = create(:hierarchy_wp_custom_field)

      expect(described_class.new(item_for(custom_field)).secondary_input_format).to eq(:short)
    end

    it "is :weight for a weighted item list field", with_ee: [:weighted_item_lists] do
      custom_field = create(:weighted_item_list_wp_custom_field)

      expect(described_class.new(item_for(custom_field)).secondary_input_format).to eq(:weight)
    end

    it "is nil for a list field" do
      custom_field = create(:list_wp_custom_field)

      expect(described_class.new(item_for(custom_field)).secondary_input_format).to be_nil
    end
  end
end
