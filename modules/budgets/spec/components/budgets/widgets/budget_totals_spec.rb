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

RSpec.describe Budgets::Widgets::BudgetTotals, type: :component do
  include Rails.application.routes.url_helpers

  def render_component(...)
    render_inline(described_class.new(...))
  end

  let(:project) { create(:project_with_types) }
  let(:current_user) do
    create(:user,
           member_with_permissions: { project => %i[view_budgets
                                                    view_cost_entries
                                                    view_cost_rates
                                                    view_time_entries
                                                    view_hourly_rates] })
  end

  subject(:rendered_component) { render_component(project, current_user:) }

  context "with budget data but no spending" do
    let!(:budget) { create(:budget, project:, base_amount: BigDecimal("10000")) }

    it "displays budget total" do
      expect(rendered_component).to have_heading("Total planned budget")
      expect(rendered_component).to have_primer_text("10,000 €")
    end

    it "displays spent ratio as percentage" do
      expect(rendered_component).to have_heading("Spent budget")
      expect(rendered_component).to have_primer_text("0.00%", color: "default")
    end

    it "displays remaining budget equal to planned budget" do
      expect(rendered_component).to have_heading("Remaining budget")
      expect(rendered_component).to have_primer_text("10,000 €", color: "default")
    end

    it "displays zero actual costs" do
      expect(rendered_component).to have_heading("Total actual costs")
      expect(rendered_component).to have_primer_text("0 €")
    end
  end

  context "with budget and spending data" do
    let(:work_package) { create(:work_package, project:, budget:) }
    let!(:budget) { create(:budget, project:, base_amount: BigDecimal("10000")) }
    let!(:hourly_rate) do
      create(:hourly_rate, user: current_user, project:, rate: 50.0, valid_from: 1.month.ago)
    end
    let!(:time_entry) do
      create(:time_entry, entity: work_package, project:, user: current_user, hours: 40, spent_on: Date.current)
    end

    it "displays actual costs based on time entries" do
      expect(rendered_component).to have_heading("Total actual costs")
      expect(rendered_component).to have_primer_text("2,000 €")
    end

    it "displays remaining budget reduced by spending" do
      expect(rendered_component).to have_heading("Remaining budget")
      expect(rendered_component).to have_primer_text("8,000 €", color: "default")
    end

    it "displays spent ratio as percentage" do
      expect(rendered_component).to have_heading("Spent budget")
      expect(rendered_component).to have_primer_text("20.00%", color: "default")
    end
  end

  context "with overspending (negative remaining)" do
    let(:work_package) { create(:work_package, project:, budget:) }
    let!(:budget) { create(:budget, project:, base_amount: BigDecimal("5000")) }
    let!(:hourly_rate) do
      create(:hourly_rate, user: current_user, project:, rate: 100.0, valid_from: 1.month.ago)
    end
    let!(:time_entry) do
      create(:time_entry, entity: work_package, project:, user: current_user, hours: 100, spent_on: Date.current)
    end

    it "displays negative remaining budget in red" do
      expect(rendered_component).to have_heading("Remaining budget")
      expect(rendered_component).to have_primer_text("-5,000 €", color: "danger")
    end

    it "displays over-100% spent ratio in red" do
      expect(rendered_component).to have_heading("Spent budget")
      expect(rendered_component).to have_primer_text("200.00%", color: "danger")
    end

    it "displays actual costs exceeding budget" do
      expect(rendered_component).to have_heading("Total actual costs")
      expect(rendered_component).to have_primer_text("10,000 €")
    end
  end

  context "without proper permissions" do
    let(:current_user) do
      create(:user, member_with_permissions: { project => %i[view_work_packages] })
    end

    it "renders nothing" do
      expect(rendered_component.to_s).to be_empty
    end
  end

  describe "#title" do
    let(:component) { described_class.new(project) }

    it "returns nil" do
      expect(component.title).to be_nil
    end
  end

  describe "#wrapper_arguments" do
    let(:component) { described_class.new(project) }

    it "returns border: false, content_padding: :none and full_width: true" do
      expect(component.wrapper_arguments).to eq({ border: false, content_padding: :none, full_width: true })
    end
  end
end
