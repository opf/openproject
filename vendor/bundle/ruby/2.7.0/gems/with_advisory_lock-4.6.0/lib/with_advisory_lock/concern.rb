require 'active_support/concern'

module WithAdvisoryLock
  module Concern
    extend ActiveSupport::Concern
    delegate :with_advisory_lock, :advisory_lock_exists?, to: 'self.class'

    module ClassMethods
      def with_advisory_lock(lock_name, options = {}, &block)
        result = with_advisory_lock_result(lock_name, options, &block)
        result.lock_was_acquired? ? result.result : false
      end

      def with_advisory_lock_result(lock_name, options = {}, &block)
        class_options = options.extract!(:force_nested_lock_support) if options.respond_to?(:fetch)
        impl = impl_class(class_options).new(connection, lock_name, options)
        impl.with_advisory_lock_if_needed(&block)
      end

      def advisory_lock_exists?(lock_name)
        impl = impl_class.new(connection, lock_name, 0)
        impl.already_locked? || !impl.yield_with_lock.lock_was_acquired?
      end

      def current_advisory_lock
        lock_stack_key = WithAdvisoryLock::Base.lock_stack.first
        lock_stack_key && lock_stack_key[0]
      end

      private

      def impl_class(options = nil)
        adapter = WithAdvisoryLock::DatabaseAdapterSupport.new(connection)
        if adapter.postgresql?
          WithAdvisoryLock::PostgreSQL
        elsif adapter.mysql?
          nested_lock = if options.respond_to?(:fetch) && [true, false].include?(options.fetch(:force_nested_lock_support, nil))
                          options.fetch(:force_nested_lock_support)
                        else
                          adapter.mysql_nested_lock_support?
                        end

          if nested_lock
            WithAdvisoryLock::MySQL
          else
            WithAdvisoryLock::MySQLNoNesting
          end
        else
          WithAdvisoryLock::Flock
        end
      end
    end
  end
end
