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

RSpec.describe Admin::CustomFields::Hierarchy::Item::ActionsComponent, type: :component,
                                                                       with_ee: %i[custom_field_hierarchies] do
  let(:custom_field) { create(:wp_custom_field, :hierarchy) }
  let(:root) { custom_field.hierarchy_root }
  let(:project) { create(:project) }
  let(:germany) { create(:hierarchy_item, parent: root, label: "Germany") }

  before { render_inline(described_class.new(item)) }

  context "for a global item" do
    let(:item) { germany }

    it "offers to add items next to and below it", :aggregate_failures do
      expect(page).to have_text(I18n.t(:button_add_item_above))
      expect(page).to have_text(I18n.t(:button_add_item_below))
      expect(page).to have_text(I18n.t(:button_add_sub_value))
    end
  end

  context "for a project item below a global item" do
    let(:item) { create(:hierarchy_item, parent: germany, label: "Cologne", project:) }

    it "offers to add items next to it, but not below it", :aggregate_failures do
      expect(page).to have_text(I18n.t(:button_add_item_above))
      expect(page).to have_text(I18n.t(:button_add_item_below))
      expect(page).to have_no_text(I18n.t(:button_add_sub_value))
    end
  end

  context "for an item below a project item" do
    let(:cologne) { create(:hierarchy_item, parent: germany, label: "Cologne", project:) }
    let(:item) { create(:hierarchy_item, parent: cologne, label: "Rheinauhafen Office", project:) }

    it "does not offer to add items", :aggregate_failures do
      expect(page).to have_no_text(I18n.t(:button_add_item_above))
      expect(page).to have_no_text(I18n.t(:button_add_item_below))
      expect(page).to have_no_text(I18n.t(:button_add_sub_value))
    end
  end
end
