#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See docs/COPYRIGHT.rdoc for more details.
#++

class VariableCostObject < CostObject
  has_many :material_budget_items, -> {
    includes(:cost_type).order(Arel.sql('material_budget_items.id ASC'))
  }, foreign_key: 'cost_object_id',
     dependent: :destroy
  has_many :labor_budget_items, -> {
    includes(:user).order(Arel.sql('labor_budget_items.id ASC'))
  }, foreign_key: 'cost_object_id',
     dependent: :destroy

  validates_associated :material_budget_items
  validates_associated :labor_budget_items

  after_update :save_material_budget_items
  after_update :save_labor_budget_items

  # override acts_as_journalized method
  def activity_type
    self.class.superclass.plural_name
  end

  def copy_from(arg)
    cost_object = (arg.is_a?(VariableCostObject) ? arg : self.class.find(arg))
    attrs = cost_object.attributes.dup
    super(attrs)
    self.labor_budget_items = cost_object.labor_budget_items.map(&:dup)
    self.material_budget_items = cost_object.material_budget_items.map(&:dup)
  end

  # Label of the current cost_object type for display in GUI.
  def type_label
    I18n.t(:label_variable_cost_object)
  end

  def material_budget
    @material_budget ||= material_budget_items.visible_costs.inject(BigDecimal('0.0000')) { |sum, i| sum += i.costs }
  end

  def labor_budget
    @labor_budget ||= labor_budget_items.visible_costs.inject(BigDecimal('0.0000')) { |sum, i| sum += i.costs }
  end

  def spent
    spent_material + spent_labor
  end

  def spent_material
    @spent_material ||= begin
      if cost_entries.blank?
        BigDecimal('0.0000')
      else
        cost_entries.visible_costs(User.current, project).sum("CASE
          WHEN #{CostEntry.table_name}.overridden_costs IS NULL THEN
            #{CostEntry.table_name}.costs
          ELSE
            #{CostEntry.table_name}.overridden_costs END").to_d
      end
    end
  end

  def spent_labor
    @spent_labor ||= begin
      if time_entries.blank?
        BigDecimal('0.0000')
      else
        time_entries.visible_costs(User.current, project).sum("CASE
          WHEN #{TimeEntry.table_name}.overridden_costs IS NULL THEN
            #{TimeEntry.table_name}.costs
          ELSE
            #{TimeEntry.table_name}.overridden_costs END").to_d
      end
    end
  end

  def new_material_budget_item_attributes=(material_budget_item_attributes)
    material_budget_item_attributes.each do |_index, attributes|
      material_budget_items.build(attributes) if attributes[:units].to_i > 0
    end
  end

  def existing_material_budget_item_attributes=(material_budget_item_attributes)
    material_budget_items.reject(&:new_record?).each do |material_budget_item|
      attributes = material_budget_item_attributes[material_budget_item.id.to_s]

      if User.current.allowed_to? :edit_cost_objects, material_budget_item.cost_object.project
        if attributes && attributes[:units].to_i > 0
          attributes[:budget] = Rate.parse_number_string(attributes[:budget])
          material_budget_item.attributes = attributes
        else
          material_budget_items.delete(material_budget_item)
        end
      end
    end
  end

  def save_material_budget_items
    material_budget_items.each do |material_budget_item|
      material_budget_item.save(validate: false)
    end
  end

  def new_labor_budget_item_attributes=(labor_budget_item_attributes)
    labor_budget_item_attributes.each do |_index, attributes|
      if attributes[:hours].to_i > 0 &&
         attributes[:user_id].to_i > 0 &&
         project.possible_assignees.map(&:id).include?(attributes[:user_id].to_i)

        item = labor_budget_items.build(attributes)
        item.cost_object = self # to please the labor_budget_item validation
      end
    end
  end

  def existing_labor_budget_item_attributes=(labor_budget_item_attributes)
    labor_budget_items.reject(&:new_record?).each do |labor_budget_item|
      attributes = labor_budget_item_attributes[labor_budget_item.id.to_s]
      if User.current.allowed_to? :edit_cost_objects, labor_budget_item.cost_object.project
        if attributes && attributes[:hours].to_i > 0 && attributes[:user_id].to_i > 0 && project.possible_assignees.map(&:id).include?(attributes[:user_id].to_i)
          attributes[:budget] = Rate.parse_number_string(attributes[:budget])
          labor_budget_item.attributes = attributes
        else
          labor_budget_items.delete(labor_budget_item)
        end
      end
    end
  end

  def save_labor_budget_items
    labor_budget_items.each do |labor_budget_item|
      labor_budget_item.save(validate: false)
    end
  end
end
