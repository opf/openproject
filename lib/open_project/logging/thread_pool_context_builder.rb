module OpenProject
  module Logging
    module ThreadPoolContextBuilder
      module_function

      ##
      # Build an object informing about current Rails connection pool
      # and active thread usage and their traces
      def build!
        thread_info = {}
        Thread.list.each_with_index do |t, i|
          thread_info[i] = {
            info: t.inspect,
            trace: t.backtrace.take(2)
          }
        end

        {
          connection_pool: ActiveRecord::Base.connection_pool.stat,
          thread_info:
        }
      end
    end
  end
end
