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

module Exports::PDF::Artefact::Budgets
  BUDGET_COLUMN_WIDTHS = [1.0, 3.0, 1.5, 1.5].freeze
  BUDGET_GROUPS = %i[material labor].freeze

  def write_artefact_budgets
    return unless budget_section?

    write_optional_page_break(threshold: styles.budgets_page_break_threshold)
    record_toc_page!("budgets")
    with_margin(styles.section_margins) do
      write_section_title(I18n.t("pdf_generator.dialog.include_budget.label"))
      with_margin(styles.budgets_table_margins) do
        pdf_table_auto_widths(budget_table_rows, budget_table_column_widths, { header: true })
      end
    end
  end

  def budget_section?
    budgets.any? && budget_enabled? && budget_allowed?
  end

  private

  def budget_enabled?
    project.module_enabled?("budgets")
  end

  def budget_allowed?
    User.current.allowed_in_project?(:view_budgets, project)
  end

  def budgets
    @budgets ||= Budget.visible(User.current).where(project_id: project.id).to_a
  end

  def budget_table_rows
    [budget_header_row] + budgets.flat_map { |budget| budget_rows(budget) } + [budget_total_row]
  end

  def budget_table_column_widths
    ratio = pdf.bounds.width / BUDGET_COLUMN_WIDTHS.sum
    BUDGET_COLUMN_WIDTHS.map { |weight| weight * ratio }
  end

  def budget_cell(value, style, align: :left, colspan: 1)
    pdf.make_cell(value.to_s, style.merge({ align:, colspan: }))
  end

  def budget_header_row
    style = styles.budgets_table_header_cell
    [
      budget_cell(MaterialBudgetItem.human_attribute_name(:units), style, align: :right),
      budget_cell(I18n.t("pdf_generator.budgets_table.description"), style),
      budget_cell(I18n.t("pdf_generator.budgets_table.cost_per_unit"), style, align: :right),
      budget_cell(I18n.t("pdf_generator.budgets_table.sum"), style, align: :right)
    ]
  end

  def budget_rows(budget)
    [budget_heading_row(budget)] +
      budget_base_amount_rows(budget) +
      BUDGET_GROUPS.flat_map { |kind| budget_group_rows(budget, kind) }
  end

  def budget_heading_row(budget)
    style = styles.budgets_table_budget_heading_cell
    [
      budget_cell("#{budget.id} #{budget.subject}", style, colspan: 3),
      budget_cell(number_to_currency(budget.budget), style, align: :right)
    ]
  end

  def budget_base_amount_rows(budget)
    return [] if budget.base_amount.blank? || budget.base_amount.zero?

    style = styles.budgets_table_cell
    [[
      budget_cell("", style),
      budget_cell(Budget.human_attribute_name(:base_amount), style),
      budget_cell("", style),
      budget_cell(number_to_currency(budget.base_amount), style, align: :right)
    ]]
  end

  def budget_group_rows(budget, kind)
    items = budget_group_items(budget, kind)
    return [] if items.empty?

    [budget_group_heading_row(budget, kind)] + items.map { |item| budget_item_row(item, kind) }
  end

  def budget_group_items(budget, kind)
    kind == :labor ? budget.labor_budget_items : budget.material_budget_items
  end

  def budget_group_heading_row(budget, kind)
    [
      budget_cell(budget_group_label(kind), styles.budgets_table_group_heading_cell, colspan: 3),
      budget_cell(budget_group_subtotal(budget, kind), styles.budgets_table_group_subtotal_cell, align: :right)
    ]
  end

  def budget_group_label(kind)
    kind == :labor ? I18n.t("pdf_generator.budgets_table.labor") : I18n.t("pdf_generator.budgets_table.material")
  end

  def budget_group_subtotal(budget, kind)
    return "" unless budget_group_rates_visible?(kind)

    number_to_currency(kind == :labor ? budget.labor_budget : budget.material_budget)
  end

  def budget_group_rates_visible?(kind)
    if kind == :labor
      User.current.allowed_in_project?(:view_hourly_rates, project) ||
        User.current.allowed_in_project?(:view_own_hourly_rate, project)
    else
      User.current.allowed_in_project?(:view_cost_rates, project)
    end
  end

  def budget_item_row(item, kind)
    style = styles.budgets_table_cell
    [
      budget_cell(budget_item_quantity(item, kind), style, align: :right),
      budget_cell(budget_item_label(item, kind), style),
      budget_cell(budget_item_cost_per_unit(item, kind), style, align: :right),
      budget_cell(budget_item_sum(item), style, align: :right)
    ]
  end

  # :hours_only keeps the quantity a single scalar, so the derived cost per unit
  # below stays well defined regardless of Setting.duration_format
  def budget_item_quantity(item, kind)
    kind == :labor ? DurationConverter.output(item.hours, format: :hours_only) : localized_float(item.units)
  end

  def budget_item_label(item, kind)
    kind == :labor ? item.principal&.name : item.cost_type.name
  end

  def budget_item_sum(item)
    item.costs_visible_by?(User.current) ? number_to_currency(item.costs) : ""
  end

  # Derived rather than read off the rate, so quantity x cost per unit equals the
  # line sum even for items overriding the calculated costs with a manual amount
  def budget_item_cost_per_unit(item, kind)
    return "" unless item.costs_visible_by?(User.current)

    quantity = kind == :labor ? item.hours : item.units
    return "" if quantity.blank? || quantity.zero?

    number_to_currency(item.costs / quantity)
  end

  def budget_total_row
    style = styles.budgets_table_total_cell
    [
      budget_cell("", style, colspan: 2),
      budget_cell(I18n.t("pdf_generator.budgets_table.total"), style, align: :right),
      budget_cell(number_to_currency(budgets.sum(&:budget)), style, align: :right)
    ]
  end
end
