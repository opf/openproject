module Delayed
  module Plugins
    class ClearLocks < Plugin
      callbacks do |lifecycle|
        lifecycle.around(:execute) do |worker, &block|
          begin
            block.call(worker)
          ensure
            Delayed::Job.clear_locks!(worker.name)
          end
        end
      end
    end
  end
end
