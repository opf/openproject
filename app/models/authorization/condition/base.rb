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

module Authorization::Condition
  class Base
    include Authorization::Visitable

    attr_accessor :if

    def initialize(scope, only_if: nil)
      @scope = scope
      @if = only_if
    end

    def to_arel(options = {})
      check_for_valid_scope

      condition = arel_statement(options) if respond_to?(:arel_statement) &&
                                             apply_condition?(options)

      condition
    end

    def and(other_condition)
      AndConcatenation.new(scope, self, other_condition)
    end

    def or(other_condition)
      OrConcatenation.new(scope, self, other_condition)
    end

    def required_tables
      self.class.required_tables
    end

    protected

    def self.table(model, name = nil)
      name ||= model.table_name.to_sym

      add_required_table(model)

      define_method name do
        model.arel_table
      end
    end

    def self.add_required_table(klass)
      @required_tables ||= []

      @required_tables << klass
    end

    def self.required_tables
      @required_tables ||= []
    end

    def apply_condition?(options)
      @if.nil? || @if.call(options)
    end

    private

    def check_for_valid_scope
      required_tables.each do |table|
        raise TableMissingInScopeError.new(self, table) unless scope.has_table?(table)
      end
    end

    attr_reader :scope
  end
end
