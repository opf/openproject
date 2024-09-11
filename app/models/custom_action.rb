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

class CustomAction < ApplicationRecord
  validates :name, length: { maximum: 255, minimum: 1 }
  serialize :actions, coder: CustomActions::Actions::Serializer
  has_and_belongs_to_many :status_conditions, class_name: "Status"
  has_and_belongs_to_many :role_conditions, class_name: "Role"
  has_and_belongs_to_many :type_conditions, class_name: "Type"
  has_and_belongs_to_many :project_conditions, class_name: "Project"

  after_save :persist_conditions

  attribute :conditions
  define_attribute_method "conditions"

  acts_as_list

  def initialize(*args)
    ret = super

    if actions.nil?
      self.actions = []
    end

    ret
  end

  def reload(*args)
    @conditions = nil

    super
  end

  def actions=(values)
    actions_will_change!
    super
  end

  def self.order_by_name
    order(:name)
  end

  def self.order_by_position
    order(:position)
  end

  def all_actions
    all_of(available_actions, actions)
  end

  def available_actions
    ::CustomActions::Register.actions.map(&:all).flatten
  end

  def all_conditions
    all_of(available_conditions, conditions)
  end

  def available_conditions
    self.class.available_conditions
  end

  def conditions
    @conditions ||= available_conditions.filter_map do |condition_class|
      condition_class.getter(self)
    end
  end

  def conditions=(new_conditions)
    conditions_will_change!
    @conditions = new_conditions
  end

  def conditions_fulfilled?(work_package, user)
    conditions.all? { |c| c.fulfilled_by?(work_package, user) }
  end

  def self.available_conditions
    ::CustomActions::Register.conditions
  end

  private

  def all_of(availables, actual)
    availables.map do |available|
      existing = actual.detect { |a| a.key == available.key }

      existing || available.new
    end
  end

  def persist_conditions
    available_conditions.map do |condition_class|
      condition = conditions.detect { |c| c.instance_of?(condition_class) }

      condition_class.setter(self, condition)
    end
  end
end
