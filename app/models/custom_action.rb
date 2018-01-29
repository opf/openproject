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
  serialize :actions, CustomActions::ActionSerializer

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

  def add_action(key, value)
    # TODO handle unknown key
    self.actions ||= []
    actions << available_actions.detect { |a| a.key == key }.new(value)
  end

  def all_actions
    available_actions.map do |action|
      existing_action = actions.detect { |a| a.key == action.key }

      if existing_action
        existing_action
      else
        action.new
      end
    end
  end

  private

  def available_actions
    ::CustomActions::Register.actions.map(&:all).flatten
  end
end

CustomActions::Register.action(CustomActions::AssignedToAction)
CustomActions::Register.action(CustomActions::StatusAction)
CustomActions::Register.action(CustomActions::PriorityAction)
CustomActions::Register.action(CustomActions::CustomFieldAction)
