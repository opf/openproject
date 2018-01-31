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

class CustomActions::BaseService
  attr_accessor :user

  def call(attributes:,
           action:)
    set_attributes(action, attributes)

    result = ServiceResult.new(success: action.save,
                               result: action)
    if block_given?
      yield result
    end

    result
  end

  private

  def set_attributes(action, attributes)
    actions = (attributes.delete(:actions) || {}).symbolize_keys
    action.attributes = attributes

    existing_action_keys = action.actions.map(&:key)

    remove_actions(action, existing_action_keys - actions.keys)
    update_actions(action, actions.slice(*existing_action_keys))
    add_actions(action, actions.slice(*(actions.keys - existing_action_keys)))
  end

  def remove_actions(action, keys)
    keys.each do |key|
      remove_action(action, key)
    end
  end

  def update_actions(action, key_values)
    key_values.each do |key, value|
      update_action(action, key, value)
    end
  end

  def add_actions(action, key_values)
    key_values.each do |key, value|
      add_action(action, key, value)
    end
  end

  def update_action(action, key, value)
    # TODO handle unknown key
    action.actions.detect { |a| a.key == key }.value = value
  end

  def add_action(action, key, value)
    # TODO handle unknown key
    action.actions << action.available_actions.detect { |a| a.key == key }.new(value)
  end

  def remove_action(action, key)
    action.actions.reject! { |a| a.key == key }
  end
end
