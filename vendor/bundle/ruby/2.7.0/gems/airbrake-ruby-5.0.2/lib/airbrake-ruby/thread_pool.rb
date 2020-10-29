module Airbrake
  # ThreadPool implements a simple thread pool that can configure the number of
  # worker threads and the size of the queue to process.
  #
  # @example
  #   # Initialize a new thread pool with 5 workers and a queue size of 100. Set
  #   # the block to be run concurrently.
  #   thread_pool = ThreadPool.new(
  #     worker_size: 5,
  #     queue_size: 100,
  #     block: proc { |message| print "ECHO: #{message}..."}
  #   )
  #
  #   # Send work.
  #   10.times { |i| thread_pool << i }
  #   #=> ECHO: 0...ECHO: 1...ECHO: 2...
  #
  # @api private
  # @since v4.6.1
  class ThreadPool
    include Loggable

    # @return [ThreadGroup] the list of workers
    # @note This is exposed for eaiser unit testing
    attr_reader :workers

    def initialize(worker_size:, queue_size:, block:)
      @worker_size = worker_size
      @queue_size = queue_size
      @block = block

      @queue = SizedQueue.new(queue_size)
      @workers = ThreadGroup.new
      @mutex = Mutex.new
      @pid = nil
      @closed = false

      has_workers?
    end

    # Adds a new message to the thread pool. Rejects messages if the queue is at
    # its capacity.
    #
    # @param [Object] message The message that gets passed to the block
    # @return [Boolean] true if the message was successfully sent to the pool,
    #   false if the queue is full
    def <<(message)
      if backlog >= @queue_size
        logger.error(
          "#{LOG_LABEL} ThreadPool has reached its capacity of " \
          "#{@queue_size} and the following message will not be " \
          "processed: #{message.inspect}",
        )
        return false
      end

      @queue << message
      true
    end

    # @return [Integer] how big the queue is at the moment
    def backlog
      @queue.size
    end

    # Checks if a thread pool has any workers. A thread pool doesn't have any
    # workers only in two cases: when it was closed or when all workers
    # crashed. An *active* thread pool doesn't have any workers only when
    # something went wrong.
    #
    # Workers are expected to crash when you +fork+ the process the workers are
    # living in. In this case we detect a +fork+ and try to revive them here.
    #
    # Another possible scenario that crashes workers is when you close the
    # instance on +at_exit+, but some other +at_exit+ hook prevents the process
    # from exiting.
    #
    # @return [Boolean] true if an instance wasn't closed, but has no workers
    # @see https://goo.gl/oydz8h Example of at_exit that prevents exit
    def has_workers?
      @mutex.synchronize do
        return false if @closed

        if @pid != Process.pid && @workers.list.empty?
          @pid = Process.pid
          @workers = ThreadGroup.new
          spawn_workers
        end

        !@closed && @workers.list.any?
      end
    end

    # Closes the thread pool making it a no-op (it shut downs all worker
    # threads). Before closing, waits on all unprocessed tasks to be processed.
    #
    # @return [void]
    # @raise [Airbrake::Error] when invoked more than one time
    def close
      threads = @mutex.synchronize do
        raise Airbrake::Error, 'this thread pool is closed already' if @closed

        unless @queue.empty?
          msg = "#{LOG_LABEL} waiting to process #{@queue.size} task(s)..."
          logger.debug(msg + ' (Ctrl-C to abort)')
        end

        @worker_size.times { @queue << :stop }
        @closed = true
        @workers.list.dup
      end

      threads.each(&:join)
      logger.debug("#{LOG_LABEL} thread pool closed")
    end

    def closed?
      @closed
    end

    def spawn_workers
      @worker_size.times { @workers.add(spawn_worker) }
      @workers.enclose
    end

    private

    def spawn_worker
      Thread.new do
        while (message = @queue.pop)
          break if message == :stop

          @block.call(message)
        end
      end
    end
  end
end
