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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "rails_helper"

RSpec.describe CustomFields::Hierarchy::ItemForm, type: :forms, with_ee: %i[custom_field_hierarchies] do
  include_context "with rendered form"

  let(:custom_field) { create(:custom_field, :hierarchy) }
  let(:target_item) { CustomField::Hierarchy::Item.new(parent: custom_field.hierarchy_root, label: "Cologne") }
  let(:model) { target_item }
  let(:params) { { target_item:, secondary_input_format: :short } }

  context "without errors" do
    it "renders no error banner" do
      expect(page).not_to have_test_selector("op-hierarchy-item-form--errors")
    end
  end

  context "with an error on an attribute without an input" do
    let(:target_item) do
      CustomField::Hierarchy::Item.new(parent: custom_field.hierarchy_root, label: "Cologne").tap do |item|
        item.errors.add(:parent, "Parent must be a global value or belong to the same project.")
      end
    end

    it "shows the error in a banner" do
      expect(page).to have_test_selector("op-hierarchy-item-form--errors",
                                         text: "Parent must be a global value or belong to the same project.")
    end
  end

  context "with an error on an attribute with an input" do
    let(:target_item) do
      CustomField::Hierarchy::Item.new(parent: custom_field.hierarchy_root, label: "Cologne").tap do |item|
        item.errors.add(:label, "Label must be unique within the same hierarchy level.")
      end
    end

    it "shows the error at the input only" do
      expect(page).not_to have_test_selector("op-hierarchy-item-form--errors")
      expect(page).to have_text("Label must be unique within the same hierarchy level.")
    end
  end
end
