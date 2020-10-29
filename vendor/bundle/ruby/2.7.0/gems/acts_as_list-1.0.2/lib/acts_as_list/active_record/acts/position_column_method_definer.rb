# frozen_string_literal: true

module ActiveRecord::Acts::List::PositionColumnMethodDefiner #:nodoc:
  def self.call(caller_class, position_column, touch_on_update)
    define_class_methods(caller_class, position_column, touch_on_update)
    define_instance_methods(caller_class, position_column)

    if mass_assignment_protection_was_used_by_user?(caller_class)
      protect_attributes_from_mass_assignment(caller_class, position_column)
    end
  end

  private

  def self.define_class_methods(caller_class, position_column, touch_on_update)
    caller_class.class_eval do
      define_singleton_method :quoted_position_column do
        @_quoted_position_column ||= connection.quote_column_name(position_column)
      end

      define_singleton_method :quoted_position_column_with_table_name do
        @_quoted_position_column_with_table_name ||= "#{caller_class.quoted_table_name}.#{quoted_position_column}"
      end

      define_singleton_method :decrement_sequentially do
        pluck(primary_key).each do |id|
          where(primary_key => id).decrement_all
        end
      end

      define_singleton_method :increment_sequentially do
        pluck(primary_key).each do |id|
          where(primary_key => id).increment_all
        end
      end

      define_singleton_method :decrement_all do
        update_all_with_touch "#{quoted_position_column} = (#{quoted_position_column_with_table_name} - 1)"
      end

      define_singleton_method :increment_all do
        update_all_with_touch "#{quoted_position_column} = (#{quoted_position_column_with_table_name} + 1)"
      end

      define_singleton_method :update_all_with_touch do |updates|
        updates += touch_record_sql if touch_on_update
        update_all(updates)
      end

      private

      define_singleton_method :touch_record_sql do
        new.touch_record_sql
      end
    end
  end

  def self.define_instance_methods(caller_class, position_column)
    caller_class.class_eval do
      attr_reader :position_changed

      define_method :position_column do
        position_column
      end

      define_method :"#{position_column}=" do |position|
        self[position_column] = position
        @position_changed = true
      end

      define_method :touch_record_sql do
        cached_quoted_now = quoted_current_time_from_proper_timezone

        timestamp_attributes_for_update_in_model.map do |attr|
          ", #{connection.quote_column_name(attr)} = #{cached_quoted_now}"
        end.join
      end

      private

      delegate :connection, to: self

      def quoted_current_time_from_proper_timezone
        connection.quote(connection.quoted_date(
          current_time_from_proper_timezone))
      end
    end
  end

  def self.mass_assignment_protection_was_used_by_user?(caller_class)
    caller_class.class_eval do
      respond_to?(:accessible_attributes) and accessible_attributes.present?
    end
  end

  def self.protect_attributes_from_mass_assignment(caller_class, position_column)
    caller_class.class_eval do
      attr_accessible position_column.to_sym
    end
  end
end
