#-- copyright
# OpenProject Costs Plugin
#
# Copyright (C) 2009 - 2014 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# version 3.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#++

module Entry
  [TimeEntry, CostEntry].each do |e| e.send :include, self end

  class Delegator < ActiveRecord::Base
    self.abstract_class = true
    class << self
      def ===(obj)
        TimeEntry === obj or CostEntry === obj
      end

      def calculate(type, *args)
        a = TimeEntry.calculate(type, *args)
        b = CostEntry.calculate(type, *args)
        case type
        when :sum, :count then a + b
        when :avg then (a + b) / 2
        when :min then [a, b].min
        when :max then [a, b].max
        else raise NotImplementedError
        end
      end

      %w[find_by_sql count_by_sql count sum].each do |meth|
        define_method(meth) { |*args| find_all(meth, *args) }
      end

      undef_method :create, :update, :delete, :destroy, :new, :update_counters,
                   :increment_counter, :decrement_counter

      %w[update_all destroy_all delete_all].each do |meth|
        define_method(meth) { |*args| send_all(meth, *args) }
      end

      private

      def find_initial(options)         find_one :find_initial,  options end

      def find_last(options)            find_one :find_last,     options end

      def find_every(options)           find_many :find_every,    options end

      def find_from_ids(_args, options)  find_many :find_from_ids, options end

      def find_one(*args)
        TimeEntry.send(*args) || CostEntry.send(*args)
      end

      def find_many(*args)
        TimeEntry.send(*args) + CostEntry.send(*args)
      end

      def send_all(*args)
        [TimeEntry.send(*args), CostEntry.send(*args)]
      end
    end
  end

  def units
    super
  rescue NoMethodError
    hours
  end

  def cost_type
    super
  rescue NoMethodError
  end

  def activity
    super
  rescue NoMethodError
  end

  def activity_id
    super
  rescue NoMethodError
  end

  def self.method_missing(*a, &b)
    Delegator.send(*a, &b)
  end
end
