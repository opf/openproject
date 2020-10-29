# frozen_string_literal: true

module ActiveRecord::Acts::List::ScopeMethodDefiner #:nodoc:
  extend ActiveSupport::Inflector

  def self.call(caller_class, scope)
    scope = idify(caller_class, scope) if scope.is_a?(Symbol)

    caller_class.class_eval do
      define_method :scope_name do
        scope
      end

      if scope.is_a?(Symbol)
        define_method :scope_condition do
          { scope => send(:"#{scope}") }
        end

        define_method :scope_changed? do
          changed.include?(scope_name.to_s)
        end

        define_method :destroyed_via_scope? do
          scope == (destroyed_by_association && destroyed_by_association.foreign_key.to_sym)
        end
      elsif scope.is_a?(Array)
        define_method :scope_condition do
          # The elements of the Array can be symbols, strings, or hashes.
          # If symbols or strings, they are treated as column names and the current value is looked up.
          # If hashes, they are treated as fixed values.
          scope.inject({}) do |hash, column_or_fixed_vals|
            if column_or_fixed_vals.is_a?(Hash)
              fixed_vals = column_or_fixed_vals
              hash.merge!(fixed_vals)
            else
              column = column_or_fixed_vals
              hash.merge!({ column.to_sym => read_attribute(column.to_sym) })
            end
          end
        end

        define_method :scope_changed? do
          (scope_condition.keys & changed.map(&:to_sym)).any?
        end

        define_method :destroyed_via_scope? do
          scope_condition.keys.include? (destroyed_by_association && destroyed_by_association.foreign_key.to_sym)
        end
      else
        define_method :scope_condition do
          eval "%{#{scope}}"
        end

        define_method :scope_changed? do
          false
        end

        define_method :destroyed_via_scope? do
          false
        end
      end

      self.scope :in_list, lambda { where("#{quoted_position_column_with_table_name} IS NOT NULL") }
    end
  end

  def self.idify(caller_class, name)
    return name if name.to_s =~ /_id$/

    if caller_class.reflections.key?(name.to_s)
      caller_class.reflections[name.to_s].foreign_key.to_sym
    else
      foreign_key(name).to_sym
    end
  end
end
