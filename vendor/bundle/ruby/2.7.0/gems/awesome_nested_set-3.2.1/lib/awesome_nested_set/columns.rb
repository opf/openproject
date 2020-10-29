# Mixed into both classes and instances to provide easy access to the column names
module CollectiveIdea #:nodoc:
  module Acts #:nodoc:
    module NestedSet #:nodoc:
      module Columns
        def left_column_name
          acts_as_nested_set_options[:left_column]
        end

        def right_column_name
          acts_as_nested_set_options[:right_column]
        end

        def depth_column_name
          acts_as_nested_set_options[:depth_column]
        end

        def parent_column_name
          acts_as_nested_set_options[:parent_column]
        end

        def primary_column_name
          acts_as_nested_set_options[:primary_column]
        end

        def order_column_name
          acts_as_nested_set_options[:order_column] || left_column_name
        end

        def scope_column_names
          Array(acts_as_nested_set_options[:scope])
        end

        def counter_cache_column_name
          acts_as_nested_set_options[:counter_cache]
        end

        def quoted_left_column_name
          model_connection.quote_column_name(left_column_name)
        end

        def quoted_right_column_name
          model_connection.quote_column_name(right_column_name)
        end

        def quoted_depth_column_name
          model_connection.quote_column_name(depth_column_name)
        end

        def quoted_primary_column_name
          model_connection.quote_column_name(primary_column_name)
        end

        def quoted_parent_column_name
          model_connection.quote_column_name(parent_column_name)
        end

        def quoted_scope_column_names
          scope_column_names.collect {|column_name| connection.quote_column_name(column_name) }
        end

        def quoted_order_column_name
          model_connection.quote_column_name(order_column_name)
        end

        def quoted_primary_key_column_full_name
          "#{quoted_table_name}.#{quoted_primary_column_name}"
        end

        def quoted_order_column_full_name
          "#{quoted_table_name}.#{quoted_order_column_name}"
        end

        def quoted_left_column_full_name
          "#{quoted_table_name}.#{quoted_left_column_name}"
        end

        def quoted_right_column_full_name
          "#{quoted_table_name}.#{quoted_right_column_name}"
        end

        def quoted_parent_column_full_name
          "#{quoted_table_name}.#{quoted_parent_column_name}"
        end

        def model_connection
          self.is_a?(Class) ? self.connection : self.class.connection
        end
      end
    end
  end
end
