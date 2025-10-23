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

require "rails_helper"

RSpec.describe Budgets::LaborBudgetItems::SubformRowComponent, type: :component do
  let(:project) { create(:project) }
  let(:budget) { create(:budget) }
  let(:table) do
    instance_double(
      Budgets::LaborBudgetItems::SubformTableComponent,
      columns: %i[hours user comments cost],
      project:,
      budget:
    )
  end

  subject(:rendered_component) do
    render_in_view_context(
      described_class,
      budget_item,
      budget,
      table,
      self
    ) do |described_class, budget_item, budget, table, spec_context|
      primer_form_with(url: "/foo", model: budget) do |f|
        spec_context.allow(table).to spec_context.receive(:form).and_return(f)

        render(described_class.new(row: budget_item, row_counter: 0, table:))
      end
    end

    rendered_content # we want a string rather Nokogiri::HTML5.fragment to workaround it stripping <tr>
  end

  context "with new budget item" do
    let(:budget_item) { build(:labor_budget_item, budget:) }

    it "renders row" do
      expect(rendered_component).to have_element :tr
    end

    it "renders cells" do
      expect(rendered_component).to have_element :td, count: 5
    end

    it "renders 'Hours' input" do
      expect(rendered_component).to have_field "Hours" do |field|
        expect(field["name"]).to eq "budget[new_labor_budget_item_attributes][0][hours]"
        expect(field["id"]).to eq "budget_new_labor_budget_item_attributes_0_hours"
      end
    end

    it "renders 'User' input" do
      expect(rendered_component).to have_select "User" do |select|
        expect(select["name"]).to eq "budget[new_labor_budget_item_attributes][0][user_id]"
        expect(select["id"]).to eq "budget_new_labor_budget_item_attributes_0_user_id"
      end
    end

    it "renders 'Comment' input" do
      expect(rendered_component).to have_field "Comment" do |field|
        expect(field["name"]).to eq "budget[new_labor_budget_item_attributes][0][comments]"
        expect(field["id"]).to eq "budget_new_labor_budget_item_attributes_0_comments"
      end
    end

    it "renders 'Budget' input" do
      expect(rendered_component).to have_field "Budget" do |field|
        expect(field["name"]).to eq "budget[new_labor_budget_item_attributes][0][amount]"
        expect(field["id"]).to eq "budget_new_labor_budget_item_attributes_0_amount"
      end
    end
  end

  context "with existing budget item" do
    let(:budget_item) { create(:labor_budget_item, budget:) }

    it "renders row" do
      expect(rendered_component).to have_element :tr
    end

    it "renders cells" do
      expect(rendered_component).to have_element :td, count: 5
    end

    it "renders 'Hours' input" do
      expect(rendered_component).to have_field "Hours" do |field|
        expect(field["name"]).to eq "budget[existing_labor_budget_item_attributes][#{budget_item.id}][hours]"
        expect(field["id"]).to eq "budget_existing_labor_budget_item_attributes_#{budget_item.id}_hours"
      end
    end

    it "renders 'User' input" do
      expect(rendered_component).to have_select "User" do |select|
        expect(select["name"]).to eq "budget[existing_labor_budget_item_attributes][#{budget_item.id}][user_id]"
        expect(select["id"]).to eq "budget_existing_labor_budget_item_attributes_#{budget_item.id}_user_id"
      end
    end

    it "renders 'Comment' input" do
      expect(rendered_component).to have_field "Comment" do |field|
        expect(field["name"]).to eq "budget[existing_labor_budget_item_attributes][#{budget_item.id}][comments]"
        expect(field["id"]).to eq "budget_existing_labor_budget_item_attributes_#{budget_item.id}_comments"
      end
    end

    it "renders 'Budget' input" do
      expect(rendered_component).to have_field "Budget" do |field|
        expect(field["name"]).to eq "budget[existing_labor_budget_item_attributes][#{budget_item.id}][amount]"
        expect(field["id"]).to eq "budget_existing_labor_budget_item_attributes_#{budget_item.id}_amount"
      end
    end
  end
end
