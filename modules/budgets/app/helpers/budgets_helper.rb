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

require "csv"

module BudgetsHelper
  include ActionView::Helpers::NumberHelper
  include Redmine::I18n

  # Check if the current user is allowed to manage the budget.  Based on Role
  # permissions.
  def allowed_management?
    User.current.allowed_in_project?(:edit_budgets, @project)
  end

  def budgets_to_csv(budgets)
    CSV.generate(col_sep: t(:general_csv_separator)) do |csv|
      # csv header fields
      headers = [
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
      ]
      csv << headers.map { |c| begin; c.to_s.encode("UTF-8"); rescue StandardError; c.to_s; end }
      # csv lines
      budgets.each do |budget|
        fields = [
          budget.id,
          budget.project.name,
          budget.subject,
          budget.author.name,
          format_date(budget.fixed_date),
          number_to_currency(budget.material_budget),
          number_to_currency(budget.labor_budget),
          number_to_currency(budget.spent),
          format_time(budget.created_at),
          format_time(budget.updated_at),
          budget.description
        ]
        csv << fields.map { |c| begin; c.to_s.encode("UTF-8"); rescue StandardError; c.to_s; end }
      end
    end
  end

  def budget_attachment_representer(message)
    ::API::V3::Budgets::BudgetRepresenter.new(message,
                                              current_user:,
                                              embed_links: true)
  end
end
