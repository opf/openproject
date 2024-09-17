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

require File.dirname(__FILE__) + "/../spec_helper"

RSpec.describe BudgetsHelper do
  let(:project) { build(:project) }
  let(:budget) { build(:budget, project:) }

  describe "#budgets_to_csv" do
    describe "WITH a list of one cost object" do
      it "outputs the cost objects attributes" do
        expected = [
          budget.id,
          budget.project.name,
          budget.subject,
          budget.author.name,
          helper.format_date(budget.fixed_date),
          helper.number_to_currency(budget.material_budget),
          helper.number_to_currency(budget.labor_budget),
          helper.number_to_currency(budget.spent),
          helper.format_time(budget.created_at),
          helper.format_time(budget.updated_at),
          budget.description
        ].join(I18n.t(:general_csv_separator))

        expect(budgets_to_csv([budget]).include?(expected)).to be_truthy
      end

      it "starts with a header explaining the fields" do
        expected = [
          "#",
          Project.model_name.human,
          Budget.human_attribute_name(:subject),
          Budget.human_attribute_name(:author),
          Budget.human_attribute_name(:fixed_date),
          Budget.human_attribute_name(:material_budget),
          Budget.human_attribute_name(:labor_budget),
          Budget.human_attribute_name(:spent),
          Budget.human_attribute_name(:created_at),
          Budget.human_attribute_name(:updated_at),
          Budget.human_attribute_name(:description)
        ].join(I18n.t(:general_csv_separator))

        expect(budgets_to_csv([budget]).start_with?(expected)).to be_truthy
      end
    end
  end
end
