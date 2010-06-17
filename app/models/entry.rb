require_dependency "time_entry"
require_dependency "cost_entry"

module Entry
  [TimeEntry, CostEntry].each { |e| e.send :include, self }

  class Delegator < ActiveRecord::Base
    self.abstract_class = true
    class << self
      def ===(obj)
        TimeEntry === obj or CostEntry === obj
      end

      def calculate(type, *args)
        a, b = TimeEntry.calculate(type, *args), CostEntry.calculate(type, *args)
        case type
        when :sum, :count then a + b
        when :avg then (a + b) / 2
        when :min then [a, b].min
        when :max then [a, b].max
        else raise NotImplementedError
        end
      end

      %[find_by_sql count_by_sql count sum].each do |meth|
        define_method(meth) { |*args| find_all(meth, *args) }
      end

      undef_method :create, :update, :delete, :destroy, :new, :update_counters,
          :increment_counter, :decrement_counter

      %w[update_all destroy_all delete_all].each do |meth|
        define_method(meth) { |*args| send_all(meth, *args) }
      end

      private
      def find_initial(options)         find_one  :find_initial,  options end
      def find_last(options)            find_one  :find_last,     options end
      def find_every(options)           find_many :find_every,    options end
      def find_from_ids(args, options)  find_many :find_from_ids, options end

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
