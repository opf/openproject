# frozen_string_literal: true

module ActiveRecord
  module Acts #:nodoc:
    module List #:nodoc:

      module ClassMethods
        # Configuration options are:
        #
        # * +column+ - specifies the column name to use for keeping the position integer (default: +position+)
        # * +scope+ - restricts what is to be considered a list. Given a symbol, it'll attach <tt>_id</tt>
        #   (if it hasn't already been added) and use that as the foreign key restriction. It's also possible
        #   to give it an entire string that is interpolated if you need a tighter scope than just a foreign key.
        #   Example: <tt>acts_as_list scope: 'todo_list_id = #{todo_list_id} AND completed = 0'</tt>
        # * +top_of_list+ - defines the integer used for the top of the list. Defaults to 1. Use 0 to make the collection
        #   act more like an array in its indexing.
        # * +add_new_at+ - specifies whether objects get added to the :top or :bottom of the list. (default: +bottom+)
        #                   `nil` will result in new items not being added to the list on create.
        # * +sequential_updates+ - specifies whether insert_at should update objects positions during shuffling
        #   one by one to respect position column unique not null constraint.
        #   Defaults to true if position column has unique index, otherwise false.
        #   If constraint is <tt>deferrable initially deferred<tt>, overriding it with false will speed up insert_at.
        # * +touch_on_update+ - configuration to disable the update of the model timestamps when the positions are updated.
        def acts_as_list(options = {})
          configuration = { column: "position", scope: "1 = 1", top_of_list: 1, add_new_at: :bottom, touch_on_update: true }
          configuration.update(options) if options.is_a?(Hash)

          caller_class = self

          ActiveRecord::Acts::List::PositionColumnMethodDefiner.call(caller_class, configuration[:column], configuration[:touch_on_update])
          ActiveRecord::Acts::List::ScopeMethodDefiner.call(caller_class, configuration[:scope])
          ActiveRecord::Acts::List::TopOfListMethodDefiner.call(caller_class, configuration[:top_of_list])
          ActiveRecord::Acts::List::AddNewAtMethodDefiner.call(caller_class, configuration[:add_new_at])

          ActiveRecord::Acts::List::AuxMethodDefiner.call(caller_class)
          ActiveRecord::Acts::List::CallbackDefiner.call(caller_class, configuration[:add_new_at])
          ActiveRecord::Acts::List::SequentialUpdatesMethodDefiner.call(caller_class, configuration[:column], configuration[:sequential_updates])

          include ActiveRecord::Acts::List::InstanceMethods
          include ActiveRecord::Acts::List::NoUpdate
        end

        # This +acts_as+ extension provides the capabilities for sorting and reordering a number of objects in a list.
        # The class that has this specified needs to have a +position+ column defined as an integer on
        # the mapped database table.
        #
        # Todo list example:
        #
        #   class TodoList < ActiveRecord::Base
        #     has_many :todo_items, order: "position"
        #   end
        #
        #   class TodoItem < ActiveRecord::Base
        #     belongs_to :todo_list
        #     acts_as_list scope: :todo_list
        #   end
        #
        #   todo_list.first.move_to_bottom
        #   todo_list.last.move_higher

        # All the methods available to a record that has had <tt>acts_as_list</tt> specified. Each method works
        # by assuming the object to be the item in the list, so <tt>chapter.move_lower</tt> would move that chapter
        # lower in the list of all chapters. Likewise, <tt>chapter.first?</tt> would return +true+ if that chapter is
        # the first in the list of all chapters.
      end

      module InstanceMethods
        # Get the current position of the item in the list
        def current_position
          position = send(position_column)
          position ? position.to_i : nil
        end

        # Insert the item at the given position (defaults to the top position of 1).
        def insert_at(position = acts_as_list_top)
          insert_at_position(position)
        end

        def insert_at!(position = acts_as_list_top)
          insert_at_position(position, true)
        end

        # Swap positions with the next lower item, if one exists.
        def move_lower
          return unless lower_item

          acts_as_list_class.transaction do
            if lower_item.current_position != current_position
              swap_positions_with(lower_item)
            else
              lower_item.decrement_position
              increment_position
            end
          end
        end

        # Swap positions with the next higher item, if one exists.
        def move_higher
          return unless higher_item

          acts_as_list_class.transaction do
            if higher_item.current_position != current_position
              swap_positions_with(higher_item)
            else
              higher_item.increment_position
              decrement_position
            end
          end
        end

        # Move to the bottom of the list. If the item is already in the list, the items below it have their
        # position adjusted accordingly.
        def move_to_bottom
          return unless in_list?
          insert_at_position bottom_position_in_list.to_i
        end

        # Move to the top of the list. If the item is already in the list, the items above it have their
        # position adjusted accordingly.
        def move_to_top
          return unless in_list?
          insert_at_position acts_as_list_top
        end

        # Removes the item from the list.
        def remove_from_list
          if in_list?
            decrement_positions_on_lower_items
            set_list_position(nil)
          end
        end

        # Move the item within scope. If a position within the new scope isn't supplied, the item will
        # be appended to the end of the list.
        def move_within_scope(scope_id)
          send("#{scope_name}=", scope_id)
          save!
        end

        # Increase the position of this item without adjusting the rest of the list.
        def increment_position
          return unless in_list?
          set_list_position(current_position + 1)
        end

        # Decrease the position of this item without adjusting the rest of the list.
        def decrement_position
          return unless in_list?
          set_list_position(current_position - 1)
        end

        def first?
          return false unless in_list?
          !higher_items(1).exists?
        end

        def last?
          return false unless in_list?
          !lower_items(1).exists?
        end

        # Return the next higher item in the list.
        def higher_item
          return nil unless in_list?
          higher_items(1).first
        end

        # Return the next n higher items in the list
        # selects all higher items by default
        def higher_items(limit=nil)
          limit ||= acts_as_list_list.count
          acts_as_list_list.
            where("#{quoted_position_column_with_table_name} <= ?", current_position).
            where("#{quoted_table_name}.#{self.class.primary_key} != ?", self.send(self.class.primary_key)).
            reorder(acts_as_list_order_argument(:desc)).
            limit(limit)
        end

        # Return the next lower item in the list.
        def lower_item
          return nil unless in_list?
          lower_items(1).first
        end

        # Return the next n lower items in the list
        # selects all lower items by default
        def lower_items(limit=nil)
          limit ||= acts_as_list_list.count
          acts_as_list_list.
            where("#{quoted_position_column_with_table_name} >= ?", current_position).
            where("#{quoted_table_name}.#{self.class.primary_key} != ?", self.send(self.class.primary_key)).
            reorder(acts_as_list_order_argument(:asc)).
            limit(limit)
        end

        # Test if this record is in a list
        def in_list?
          !not_in_list?
        end

        def not_in_list?
          current_position.nil?
        end

        def default_position
          acts_as_list_class.column_defaults[position_column.to_s]
        end

        def default_position?
          default_position && default_position == current_position
        end

        # Sets the new position and saves it
        def set_list_position(new_position, raise_exception_if_save_fails=false)
          self[position_column] = new_position
          raise_exception_if_save_fails ? save! : save
        end

        private

        def swap_positions_with(item)
          item_position = item.current_position

          item.set_list_position(current_position)
          set_list_position(item_position)
        end

        def acts_as_list_list
          acts_as_list_class.unscope(:select, :where).where(scope_condition)
        end

        # Poorly named methods. They will insert the item at the desired position if the position
        # has been set manually using position=, not necessarily the top or bottom of the list:

        def add_to_list_top
          if assume_default_position?
            increment_positions_on_all_items
            self[position_column] = acts_as_list_top
          else
            increment_positions_on_lower_items(self[position_column], id)
          end

          # Make sure we know that we've processed this scope change already
          @scope_changed = false

          # Don't halt the callback chain
          true
        end

        def add_to_list_bottom
          if assume_default_position?
            self[position_column] = bottom_position_in_list.to_i + 1
          else
            increment_positions_on_lower_items(self[position_column], id)
          end

          # Make sure we know that we've processed this scope change already
          @scope_changed = false

          # Don't halt the callback chain
          true
        end

        def assume_default_position?
          not_in_list? ||
          persisted? && internal_scope_changed? && !position_changed ||
          default_position?
        end

        # Overwrite this method to define the scope of the list changes
        def scope_condition() {} end

        # Returns the bottom position number in the list.
        #   bottom_position_in_list    # => 2
        def bottom_position_in_list(except = nil)
          item = bottom_item(except)
          item ? item.current_position : acts_as_list_top - 1
        end

        # Returns the bottom item
        def bottom_item(except = nil)
          scope = acts_as_list_list

          if except
            scope = scope.where("#{quoted_table_name}.#{self.class.primary_key} != ?", except.id)
          end

          scope.in_list.reorder(acts_as_list_order_argument(:desc)).first
        end

        # Forces item to assume the bottom position in the list.
        def assume_bottom_position
          set_list_position(bottom_position_in_list(self).to_i + 1)
        end

        # Forces item to assume the top position in the list.
        def assume_top_position
          set_list_position(acts_as_list_top)
        end

        # This has the effect of moving all the higher items down one.
        def increment_positions_on_higher_items
          return unless in_list?
          acts_as_list_list.where("#{quoted_position_column_with_table_name} < ?", current_position).increment_all
        end

        # This has the effect of moving all the lower items down one.
        def increment_positions_on_lower_items(position, avoid_id = nil)
          scope = acts_as_list_list

          if avoid_id
            scope = scope.where("#{quoted_table_name}.#{self.class.primary_key} != ?", avoid_id)
          end

          if sequential_updates?
            scope.where("#{quoted_position_column_with_table_name} >= ?", position).reorder(acts_as_list_order_argument(:desc)).increment_sequentially
          else
            scope.where("#{quoted_position_column_with_table_name} >= ?", position).increment_all
          end
        end

        # This has the effect of moving all the higher items up one.
        def decrement_positions_on_higher_items(position)
          acts_as_list_list.where("#{quoted_position_column_with_table_name} <= ?", position).decrement_all
        end

        # This has the effect of moving all the lower items up one.
        def decrement_positions_on_lower_items(position=current_position)
          return unless in_list?

          if sequential_updates?
            acts_as_list_list.where("#{quoted_position_column_with_table_name} > ?", position).reorder(acts_as_list_order_argument(:asc)).decrement_sequentially
          else
            acts_as_list_list.where("#{quoted_position_column_with_table_name} > ?", position).decrement_all
          end
        end

        # Increments position (<tt>position_column</tt>) of all items in the list.
        def increment_positions_on_all_items
          acts_as_list_list.increment_all
        end

        # Reorders intermediate items to support moving an item from old_position to new_position.
        # unique constraint prevents regular increment_all and forces to do increments one by one
        # http://stackoverflow.com/questions/7703196/sqlite-increment-unique-integer-field
        # both SQLite and PostgreSQL (and most probably MySQL too) has same issue
        # that's why *sequential_updates?* check alters implementation behavior
        def shuffle_positions_on_intermediate_items(old_position, new_position, avoid_id = nil)
          return if old_position == new_position
          scope = acts_as_list_list

          if avoid_id
            scope = scope.where("#{quoted_table_name}.#{self.class.primary_key} != ?", avoid_id)
          end

          if old_position < new_position
            # Decrement position of intermediate items
            #
            # e.g., if moving an item from 2 to 5,
            # move [3, 4, 5] to [2, 3, 4]
            items = scope.where(
              "#{quoted_position_column_with_table_name} > ?", old_position
            ).where(
              "#{quoted_position_column_with_table_name} <= ?", new_position
            )

            if sequential_updates?
              items.reorder(acts_as_list_order_argument(:asc)).decrement_sequentially
            else
              items.decrement_all
            end
          else
            # Increment position of intermediate items
            #
            # e.g., if moving an item from 5 to 2,
            # move [2, 3, 4] to [3, 4, 5]
            items = scope.where(
              "#{quoted_position_column_with_table_name} >= ?", new_position
            ).where(
              "#{quoted_position_column_with_table_name} < ?", old_position
            )

            if sequential_updates?
              items.reorder(acts_as_list_order_argument(:desc)).increment_sequentially
            else
              items.increment_all
            end
          end
        end

        def insert_at_position(position, raise_exception_if_save_fails=false)
          raise ArgumentError.new("position cannot be lower than top") if position < acts_as_list_top
          return set_list_position(position, raise_exception_if_save_fails) if new_record?
          with_lock do
            if in_list?
              old_position = current_position
              return if position == old_position
              # temporary move after bottom with gap, avoiding duplicate values
              # gap is required to leave room for position increments
              # positive number will be valid with unique not null check (>= 0) db constraint
              temporary_position = bottom_position_in_list + 2
              set_list_position(temporary_position, raise_exception_if_save_fails)
              shuffle_positions_on_intermediate_items(old_position, position, id)
            else
              increment_positions_on_lower_items(position)
            end
            set_list_position(position, raise_exception_if_save_fails)
          end
        end

        def update_positions
          return unless position_before_save_changed?

          old_position = position_before_save || bottom_position_in_list + 1

          return unless current_position && acts_as_list_list.where(
            "#{quoted_position_column_with_table_name} = #{current_position}"
          ).count > 1

          shuffle_positions_on_intermediate_items old_position, current_position, id
        end

        def position_before_save_changed?
          if active_record_version_is?('>= 5.1')
            saved_change_to_attribute? position_column
          else
            attribute_changed? position_column
          end
        end

        def position_before_save
          if active_record_version_is?('>= 5.1')
            attribute_before_last_save position_column
          else
            attribute_was position_column
          end
        end

        def internal_scope_changed?
          return @scope_changed if defined?(@scope_changed)

          @scope_changed = scope_changed?
        end

        def clear_scope_changed
          remove_instance_variable(:@scope_changed) if defined?(@scope_changed)
        end

        def check_scope
          if internal_scope_changed?
            cached_changes = changes

            cached_changes.each { |attribute, values| send("#{attribute}=", values[0]) }
            send('decrement_positions_on_lower_items') if lower_item
            cached_changes.each { |attribute, values| send("#{attribute}=", values[1]) }

            send("add_to_list_#{add_new_at}") if add_new_at.present?
          end
        end

        # This check is skipped if the position is currently the default position from the table
        # as modifying the default position on creation is handled elsewhere
        def check_top_position
          if current_position && !default_position? && current_position < acts_as_list_top
            self[position_column] = acts_as_list_top
          end
        end

        # When using raw column name it must be quoted otherwise it can raise syntax errors with SQL keywords (e.g. order)
        def quoted_position_column
          @_quoted_position_column ||= self.class.connection.quote_column_name(position_column)
        end

        # Used in order clauses
        def quoted_table_name
          @_quoted_table_name ||= acts_as_list_class.quoted_table_name
        end

        def quoted_position_column_with_table_name
          @_quoted_position_column_with_table_name ||= "#{quoted_table_name}.#{quoted_position_column}"
        end

        def acts_as_list_order_argument(direction = :asc)
          { position_column => direction }
        end

        def active_record_version_is?(version_requirement)
          requirement = Gem::Requirement.new(version_requirement)
          version = Gem.loaded_specs['activerecord'].version
          requirement.satisfied_by?(version)
        end
      end

    end
  end
end
