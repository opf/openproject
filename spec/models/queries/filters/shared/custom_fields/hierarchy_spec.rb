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

require "spec_helper"

RSpec.describe Queries::Filters::Shared::CustomFields::Hierarchy,
               with_ee: %i[custom_field_hierarchies] do
  # `let!` (not shared_let): the hierarchy format is only valid while the EE
  # token from `with_ee` is active, which is per-example.
  let(:service) { CustomFields::Hierarchy::HierarchicalItemService.new }
  let!(:custom_field) { create(:user_custom_field, :hierarchy, name: "Job title") }
  let!(:developer) do
    service.insert_item(contract_class: CustomFields::Hierarchy::InsertListItemContract,
                        parent: custom_field.hierarchy_root, label: "Developer").value!
  end

  # The filter UserQuery builds for this hierarchy custom field, with its values
  # set as strings (how they come back when editing a stored filter).
  def filter_for(values)
    UserQuery.new
             .available_filters
             .detect { |f| f.name.to_s == custom_field.column_name }
             .tap do |filter|
               filter.operator = filter.available_operators.first.to_s
               filter.values = values
             end
  end

  describe "#autocomplete_options" do
    it "pre-selects items whose (integer) id matches a stored (string) value" do
      options = filter_for([developer.id.to_s]).autocomplete_options

      expect(options[:items].pluck(:id)).to include(developer.id)
      expect(options[:model].pluck(:id)).to eq([developer.id])
    end

    it "pre-selects nothing when there are no values" do
      expect(filter_for([]).autocomplete_options[:model]).to eq([])
    end
  end
end
