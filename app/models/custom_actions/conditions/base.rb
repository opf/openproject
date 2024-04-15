#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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

class CustomActions::Conditions::Base
  attr_reader :values

  prepend CustomActions::ValuesToInteger
  include CustomActions::ValidateAllowedValue

  def initialize(values = nil)
    self.values = values
  end

  def values=(values)
    @values = Array(values)
  end

  def allowed_values
    associated
      .map { |value, label| { value:, label: } }
  end

  def human_name
    WorkPackage.human_attribute_name(self.class.key)
  end

  def fulfilled_by?(work_package, _user)
    values.empty? ||
    (work_package.respond_to?(:"#{key}_id") && values.include?(work_package.send(:"#{key}_id")))
  end

  def key
    self.class.key
  end

  def self.key
    raise NotImplementedError
  end

  def validate(errors)
    validate_allowed_value(errors, :conditions)
  end

  def self.getter(custom_action)
    ids = custom_action.send(association_ids)

    new(ids) if ids.any?
  end

  def self.setter(custom_action, condition)
    if condition
      custom_action.send(:"#{association_ids}=", condition.values)
    else
      custom_action.send(:"#{association_key}").clear
    end
  end

  def self.custom_action_scope(work_packages, user)
    custom_action_scope_has_current(work_packages, user)
      .or(custom_action_scope_has_no)
  end

  def self.custom_action_scope_has_current(work_packages, _user)
    CustomAction
      .includes(association_key)
      .where(habtm_table => { key_id => Array(work_packages).map { |w| w.send(key_id) }.uniq })
  end
  private_class_method :custom_action_scope_has_current

  def self.custom_action_scope_has_no
    CustomAction
      .includes(association_key)
      .where(habtm_table => { key_id => nil })
  end
  private_class_method :custom_action_scope_has_no

  def self.pluralized_key
    key.to_s.pluralize.to_sym
  end
  private_class_method :pluralized_key

  def self.habtm_table
    :"custom_actions_#{pluralized_key}"
  end
  private_class_method :habtm_table

  def self.key_id
    @key_id ||= :"#{key}_id"
  end
  private_class_method :key_id

  def self.association_key
    :"#{key}_conditions"
  end
  private_class_method :association_key

  def self.association_ids
    :"#{key}_condition_ids"
  end
  private_class_method :association_ids
end
