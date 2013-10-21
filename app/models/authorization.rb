#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2014 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

class Authorization
  def self.scope(name, &block)
    allowance = scope_instance(name)

    allowance.instance_eval(&block) if block_given?

    allowance
  end

  # Removes the scope from the known scopes.
  # Mostly used for testing for now.
  def self.drop_scope(name)
    drop_scope_instance(name)
  end

  def table(name, definition = nil)
    define_table(name, definition)
  end

  def condition(name, definition, options = {})
    define_condition(name, definition, only_if: options[:if])
  end

  def alter_condition(name, new_condition)
    replace_condition_with(name, new_condition) if self.respond_to?(name)

    define_condition(name, new_condition)
  end

  def scope_target(table)
    @scope_target = table
  end

  def scope(options = {})
    @scope_target.to_ar_scope(options).uniq
  end

  delegate :has_table?, to: :tables
  delegate :name, to: :tables, prefix: 'table'

  def print
    visitor = Visitor::ToS.new(self)
    visitor.visit(@scope_target)
  end

  private

  def self.scope_instance(name)
    scopes[name]
  end

  def self.scopes
    @scopes ||= Hash.new do |hash, scope_name|
      allowance = Authorization.new

      add_scope_method(scope_name, allowance)

      hash[scope_name] = allowance
    end
  end

  def self.drop_scope_instance(name)
    return unless scopes[name]

    scopes.delete(name)

    singleton_class.send(:remove_method, name)
  end

  def define_table(name, definition = nil)
    new_table = tables.define(name, definition)

    define_singleton_method name do
      new_table
    end
  end

  def tables
    @tables ||= Table::Map.new(self)
  end

  def define_condition(name, definition, only_if: nil)
    instance = conditions.define(name, definition, only_if: only_if)

    define_singleton_method name do
      instance
    end
  end

  def replace_condition_with(name, new_condition)
    orig_condition = self.send(name)
    new_condition = conditions.define(name, new_condition)

    visitor = Visitor::ConditionModifier.new(self, orig_condition, new_condition)
    visitor.visit(@scope_target)
  end

  def conditions
    @conditions ||= Condition::Map.new(self)
  end

  def self.add_scope_method(name, allowance)
    method_body = ->(options = {}) { allowance.scope(options) }

    singleton_class.send(:define_method, name, method_body)
  end
end
