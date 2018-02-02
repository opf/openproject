#-- encoding: UTF-8

#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

class CustomAction < ActiveRecord::Base
  validates :name, length: { maximum: 255, minimum: 1 }
  serialize :actions, CustomActions::Actions::Serializer
  has_and_belongs_to_many :statuses
  has_and_belongs_to_many :roles

  def initialize(*args)
    ret = super

    if actions.nil?
      self.actions = []
    end

    ret
  end

  def self.order_by_name
    order(:name)
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
    ::CustomActions::Register.conditions
  end

  def conditions
    # TODO generalize and move into condition
    return_conditions = []

    if statuses.any?
      return_conditions << CustomActions::Conditions::Status.new(statuses.map(&:id))
    end

    if roles.any?
      return_conditions << CustomActions::Conditions::Role.new(statuses.map(&:id))
    end

    return_conditions
  end

  def conditions=(new_conditions)
    # TODO place in after save hook so that validations can take place before
    # TODO generalize and move into condition
    new_conditions.each do |new_condition|
      send(:"#{new_condition.key}_ids=", new_condition.values)
    end
  end

  private

  def all_of(availables, actual)
    availables.map do |available|
      existing = actual.detect { |a| a.key == available.key }

      if existing
        existing
      else
        available.new
      end
    end
  end
end

CustomActions::Register.action(CustomActions::Actions::AssignedTo)
CustomActions::Register.action(CustomActions::Actions::Status)
CustomActions::Register.action(CustomActions::Actions::Priority)
CustomActions::Register.action(CustomActions::Actions::CustomField)

CustomActions::Register.condition(CustomActions::Conditions::Status)
CustomActions::Register.condition(CustomActions::Conditions::Role)
