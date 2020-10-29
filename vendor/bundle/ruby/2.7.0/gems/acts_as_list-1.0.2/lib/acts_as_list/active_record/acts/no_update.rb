# frozen_string_literal: true

module ActiveRecord
  module Acts
    module List
      module NoUpdate

        def self.included(base)
          base.extend ClassMethods
        end

        class ArrayTypeError < ArgumentError
          def initialize
            super("The first argument must be an array")
          end
        end

        class DisparityClassesError < ArgumentError
          def initialize
            super("The first argument should contain ActiveRecord or ApplicationRecord classes")
          end
        end

        module ClassMethods
          # Lets you selectively disable all act_as_list database updates
          # for the duration of a block.
          #
          # ==== Examples
          #
          # class TodoList < ActiveRecord::Base
          #   has_many :todo_items, -> { order(position: :asc) }
          # end
          #
          # class TodoItem < ActiveRecord::Base
          #   belongs_to :todo_list
          #
          #   acts_as_list scope: :todo_list
          # end
          #
          # TodoItem.acts_as_list_no_update do
          #   TodoList.first.update(position: 2)
          # end
          #
          # You can also pass an array of classes as an argument to disable database updates on just those classes.
          # It can be any ActiveRecord class that has acts_as_list enabled.
          #
          # ==== Examples
          #
          # class TodoList < ActiveRecord::Base
          #   has_many :todo_items, -> { order(position: :asc) }
          #   acts_as_list
          # end
          #
          # class TodoItem < ActiveRecord::Base
          #   belongs_to :todo_list
          #   has_many :todo_attachments, -> { order(position: :asc) }
          #
          #   acts_as_list scope: :todo_list
          # end
          #
          # class TodoAttachment < ActiveRecord::Base
          #   belongs_to :todo_list
          #   acts_as_list scope: :todo_item
          # end
          #
          # TodoItem.acts_as_list_no_update([TodoAttachment]) do
          #   TodoItem.find(10).update(position: 2)
          #   TodoAttachment.find(10).update(position: 1)
          #   TodoAttachment.find(11).update(position: 2)
          #   TodoList.find(2).update(position: 3) # For this instance the callbacks will be called because we haven't passed the class as an argument
          # end

          def acts_as_list_no_update(extra_classes = [], &block)
            return raise ArrayTypeError unless extra_classes.is_a?(Array)

            extra_classes << self

            return raise DisparityClassesError unless active_record_objects?(extra_classes)

            NoUpdate.apply_to(extra_classes, &block)
          end

          private

          def active_record_objects?(extra_classes)
            extra_classes.all? { |klass| klass.ancestors.include? ActiveRecord::Base }
          end
        end

        class << self
          def apply_to(klasses)
            klasses.map {|klass| add_klass(klass)}
            yield
          ensure
            klasses.map {|klass| remove_klass(klass)}
          end

          def applied_to?(klass)
            !(klass.ancestors & extracted_klasses.keys).empty?
          end

          private

          def extracted_klasses
            Thread.current[:act_as_list_no_update] ||= {}
          end

          def add_klass(klass)
            extracted_klasses[klass] = 0 unless extracted_klasses.key?(klass)
            extracted_klasses[klass] += 1
          end

          def remove_klass(klass)
            extracted_klasses[klass] -= 1
            extracted_klasses.delete(klass) if extracted_klasses[klass] <= 0
          end
        end

        def act_as_list_no_update?
          NoUpdate.applied_to?(self.class)
        end
      end
    end
  end
end
