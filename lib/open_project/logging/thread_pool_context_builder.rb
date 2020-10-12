module OpenProject
  module Logging
    class ThreadPoolContextBuilder
      ##
      # Build an object informing about current Rails connection pool
      # and active thread usage and their traces
      def self.build!
        thread_info = {}
        Thread.list.each_with_index do |t, i|
          thread_info[i] = {
            info: t.inspect,
            trace: t.backtrace.take(2)
          }
        end

        {
          connection_pool: ActiveRecord::Base.connection_pool.stat,
          thread_info: thread_info
        }
      end
    end
  end
end
