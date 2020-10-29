require "thread"
require "active_support/core_ext/class/attribute_accessors"
require "active_support/core_ext/module/aliasing"
require "active_support/core_ext/module/attribute_accessors"
require "active_support/concern"

module ActiveRecord
  module SessionStore
    module Extension
      module LoggerSilencer
        extend ActiveSupport::Concern

        included do
          cattr_accessor :silencer
          self.silencer = true
          alias_method :level_without_threadsafety, :level
          alias_method :level, :level_with_threadsafety
          alias_method :add_without_threadsafety, :add
          alias_method :add, :add_with_threadsafety
        end

        def thread_level
          Thread.current[thread_hash_level_key]
        end

        def thread_level=(level)
          Thread.current[thread_hash_level_key] = level
        end

        def level_with_threadsafety
          thread_level || level_without_threadsafety
        end

        def add_with_threadsafety(severity, message = nil, progname = nil, &block)
          if (defined?(@logdev) && @logdev.nil?) || (severity || UNKNOWN) < level
            true
          else
            add_without_threadsafety(severity, message, progname, &block)
          end
        end

        # Silences the logger for the duration of the block.
        def silence_logger(temporary_level = Logger::ERROR)
          if silencer
            begin
              self.thread_level = temporary_level
              yield self
            ensure
              self.thread_level = nil
            end
          else
            yield self
          end
        end

        for severity in Logger::Severity.constants
          class_eval <<-EOT, __FILE__, __LINE__ + 1
            def #{severity.downcase}?                # def debug?
              Logger::#{severity} >= level           #   DEBUG >= level
            end                                      # end
          EOT
        end

        private

        def thread_hash_level_key
          @thread_hash_level_key ||= :"ThreadSafeLogger##{object_id}@level"
        end
      end
    end

    class NilLogger
      def self.silence_logger
        yield
      end
    end
  end
end
