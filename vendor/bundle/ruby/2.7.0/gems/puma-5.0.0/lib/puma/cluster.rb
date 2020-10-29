# frozen_string_literal: true

require 'puma/runner'
require 'puma/util'
require 'puma/plugin'

require 'time'

module Puma
  # This class is instantiated by the `Puma::Launcher` and used
  # to boot and serve a Ruby application when puma "workers" are needed
  # i.e. when using multi-processes. For example `$ puma -w 5`
  #
  # At the core of this class is running an instance of `Puma::Server` which
  # gets created via the `start_server` method from the `Puma::Runner` class
  # that this inherits from.
  #
  # An instance of this class will spawn the number of processes passed in
  # via the `spawn_workers` method call. Each worker will have it's own
  # instance of a `Puma::Server`.
  class Cluster < Runner
    def initialize(cli, events)
      super cli, events

      @phase = 0
      @workers = []
      @next_check = Time.now

      @phased_restart = false
    end

    def stop_workers
      log "- Gracefully shutting down workers..."
      @workers.each { |x| x.term }

      begin
        loop do
          wait_workers
          break if @workers.reject {|w| w.pid.nil?}.empty?
          sleep 0.2
        end
      rescue Interrupt
        log "! Cancelled waiting for workers"
      end
    end

    def start_phased_restart
      @phase += 1
      log "- Starting phased worker restart, phase: #{@phase}"

      # Be sure to change the directory again before loading
      # the app. This way we can pick up new code.
      dir = @launcher.restart_dir
      log "+ Changing to #{dir}"
      Dir.chdir dir
    end

    def redirect_io
      super

      @workers.each { |x| x.hup }
    end

    class Worker
      def initialize(idx, pid, phase, options)
        @index = idx
        @pid = pid
        @phase = phase
        @stage = :started
        @signal = "TERM"
        @options = options
        @first_term_sent = nil
        @started_at = Time.now
        @last_checkin = Time.now
        @last_status = {}
        @term = false
      end

      attr_reader :index, :pid, :phase, :signal, :last_checkin, :last_status, :started_at

      # @version 5.0.0
      attr_writer :pid, :phase

      def booted?
        @stage == :booted
      end

      def boot!
        @last_checkin = Time.now
        @stage = :booted
      end

      def term?
        @term
      end

      def ping!(status)
        @last_checkin = Time.now
        require 'json'
        @last_status = JSON.parse(status, symbolize_names: true)
      end

      # @see Puma::Cluster#check_workers
      # @version 5.0.0
      def ping_timeout
        @last_checkin +
          (booted? ?
            @options[:worker_timeout] :
            @options[:worker_boot_timeout]
          )
      end

      def term
        begin
          if @first_term_sent && (Time.now - @first_term_sent) > @options[:worker_shutdown_timeout]
            @signal = "KILL"
          else
            @term ||= true
            @first_term_sent ||= Time.now
          end
          Process.kill @signal, @pid if @pid
        rescue Errno::ESRCH
        end
      end

      def kill
        @signal = 'KILL'
        term
      end

      def hup
        Process.kill "HUP", @pid
      rescue Errno::ESRCH
      end
    end

    def spawn_workers
      diff = @options[:workers] - @workers.size
      return if diff < 1

      master = Process.pid
      if @options[:fork_worker]
        @fork_writer << "-1\n"
      end

      diff.times do
        idx = next_worker_index

        if @options[:fork_worker] && idx != 0
          @fork_writer << "#{idx}\n"
          pid = nil
        else
          pid = spawn_worker(idx, master)
        end

        debug "Spawned worker: #{pid}"
        @workers << Worker.new(idx, pid, @phase, @options)
      end

      if @options[:fork_worker] &&
        @workers.all? {|x| x.phase == @phase}

        @fork_writer << "0\n"
      end
    end

    # @version 5.0.0
    def spawn_worker(idx, master)
      @launcher.config.run_hooks :before_worker_fork, idx, @launcher.events

      pid = fork { worker(idx, master) }
      if !pid
        log "! Complete inability to spawn new workers detected"
        log "! Seppuku is the only choice."
        exit! 1
      end

      @launcher.config.run_hooks :after_worker_fork, idx, @launcher.events
      pid
    end

    def cull_workers
      diff = @workers.size - @options[:workers]
      return if diff < 1

      debug "Culling #{diff.inspect} workers"

      workers_to_cull = @workers[-diff,diff]
      debug "Workers to cull: #{workers_to_cull.inspect}"

      workers_to_cull.each do |worker|
        log "- Worker #{worker.index} (pid: #{worker.pid}) terminating"
        worker.term
      end
    end

    def next_worker_index
      all_positions =  0...@options[:workers]
      occupied_positions = @workers.map { |w| w.index }
      available_positions = all_positions.to_a - occupied_positions
      available_positions.first
    end

    def all_workers_booted?
      @workers.count { |w| !w.booted? } == 0
    end

    def check_workers
      return if @next_check >= Time.now

      @next_check = Time.now + Const::WORKER_CHECK_INTERVAL

      timeout_workers
      wait_workers
      cull_workers
      spawn_workers

      if all_workers_booted?
        # If we're running at proper capacity, check to see if
        # we need to phase any workers out (which will restart
        # in the right phase).
        #
        w = @workers.find { |x| x.phase != @phase }

        if w
          log "- Stopping #{w.pid} for phased upgrade..."
          unless w.term?
            w.term
            log "- #{w.signal} sent to #{w.pid}..."
          end
        end
      end

      @next_check = [
        @workers.reject(&:term?).map(&:ping_timeout).min,
        @next_check
      ].compact.min
    end

    def wakeup!
      return unless @wakeup

      begin
        @wakeup.write "!" unless @wakeup.closed?
      rescue SystemCallError, IOError
        Thread.current.purge_interrupt_queue if Thread.current.respond_to? :purge_interrupt_queue
      end
    end

    def worker(index, master)
      title  = "puma: cluster worker #{index}: #{master}"
      title += " [#{@options[:tag]}]" if @options[:tag] && !@options[:tag].empty?
      $0 = title

      Signal.trap "SIGINT", "IGNORE"
      Signal.trap "SIGCHLD", "DEFAULT"

      fork_worker = @options[:fork_worker] && index == 0

      @workers = []
      if !@options[:fork_worker] || fork_worker
        @master_read.close
        @suicide_pipe.close
        @fork_writer.close
      end

      Thread.new do
        Puma.set_thread_name "worker check pipe"
        IO.select [@check_pipe]
        log "! Detected parent died, dying"
        exit! 1
      end

      # If we're not running under a Bundler context, then
      # report the info about the context we will be using
      if !ENV['BUNDLE_GEMFILE']
        if File.exist?("Gemfile")
          log "+ Gemfile in context: #{File.expand_path("Gemfile")}"
        elsif File.exist?("gems.rb")
          log "+ Gemfile in context: #{File.expand_path("gems.rb")}"
        end
      end

      # Invoke any worker boot hooks so they can get
      # things in shape before booting the app.
      @launcher.config.run_hooks :before_worker_boot, index, @launcher.events

      server = @server ||= start_server
      restart_server = Queue.new << true << false

      if fork_worker
        restart_server.clear
        worker_pids = []
        Signal.trap "SIGCHLD" do
          wakeup! if worker_pids.reject! do |p|
            Process.wait(p, Process::WNOHANG) rescue true
          end
        end

        Thread.new do
          Puma.set_thread_name "worker fork pipe"
          while (idx = @fork_pipe.gets)
            idx = idx.to_i
            if idx == -1 # stop server
              if restart_server.length > 0
                restart_server.clear
                server.begin_restart(true)
                @launcher.config.run_hooks :before_refork, nil, @launcher.events
                nakayoshi_gc
              end
            elsif idx == 0 # restart server
              restart_server << true << false
            else # fork worker
              worker_pids << pid = spawn_worker(idx, master)
              @worker_write << "f#{pid}:#{idx}\n" rescue nil
            end
          end
        end
      end

      Signal.trap "SIGTERM" do
        @worker_write << "e#{Process.pid}\n" rescue nil
        server.stop
        restart_server << false
      end

      begin
        @worker_write << "b#{Process.pid}:#{index}\n"
      rescue SystemCallError, IOError
        Thread.current.purge_interrupt_queue if Thread.current.respond_to? :purge_interrupt_queue
        STDERR.puts "Master seems to have exited, exiting."
        return
      end

      Thread.new(@worker_write) do |io|
        Puma.set_thread_name "stat payload"

        while true
          sleep Const::WORKER_CHECK_INTERVAL
          begin
            require 'json'
            io << "p#{Process.pid}#{server.stats.to_json}\n"
          rescue IOError
            Thread.current.purge_interrupt_queue if Thread.current.respond_to? :purge_interrupt_queue
            break
          end
        end
      end

      server.run.join while restart_server.pop

      # Invoke any worker shutdown hooks so they can prevent the worker
      # exiting until any background operations are completed
      @launcher.config.run_hooks :before_worker_shutdown, index, @launcher.events
    ensure
      @worker_write << "t#{Process.pid}\n" rescue nil
      @worker_write.close
    end

    def restart
      @restart = true
      stop
    end

    def phased_restart
      return false if @options[:preload_app]

      @phased_restart = true
      wakeup!

      true
    end

    def stop
      @status = :stop
      wakeup!
    end

    def stop_blocked
      @status = :stop if @status == :run
      wakeup!
      @control.stop(true) if @control
      Process.waitall
    end

    def halt
      @status = :halt
      wakeup!
    end

    def reload_worker_directory
      dir = @launcher.restart_dir
      log "+ Changing to #{dir}"
      Dir.chdir dir
    end

    # Inside of a child process, this will return all zeroes, as @workers is only populated in
    # the master process.
    def stats
      old_worker_count = @workers.count { |w| w.phase != @phase }
      worker_status = @workers.map do |w|
        {
          started_at: w.started_at.utc.iso8601,
          pid: w.pid,
          index: w.index,
          phase: w.phase,
          booted: w.booted?,
          last_checkin: w.last_checkin.utc.iso8601,
          last_status: w.last_status,
        }
      end

      {
        started_at: @started_at.utc.iso8601,
        workers: @workers.size,
        phase: @phase,
        booted_workers: worker_status.count { |w| w[:booted] },
        old_workers: old_worker_count,
        worker_status: worker_status,
      }
    end

    def preload?
      @options[:preload_app]
    end

    # @version 5.0.0
    def fork_worker!
      if (worker = @workers.find { |w| w.index == 0 })
        worker.phase += 1
      end
      phased_restart
    end

    # We do this in a separate method to keep the lambda scope
    # of the signals handlers as small as possible.
    def setup_signals
      if @options[:fork_worker]
        Signal.trap "SIGURG" do
          fork_worker!
        end

        # Auto-fork after the specified number of requests.
        if (fork_requests = @options[:fork_worker].to_i) > 0
          @launcher.events.register(:ping!) do |w|
            fork_worker! if w.index == 0 &&
              w.phase == 0 &&
              w.last_status[:requests_count] >= fork_requests
          end
        end
      end

      Signal.trap "SIGCHLD" do
        wakeup!
      end

      Signal.trap "TTIN" do
        @options[:workers] += 1
        wakeup!
      end

      Signal.trap "TTOU" do
        @options[:workers] -= 1 if @options[:workers] >= 2
        wakeup!
      end

      master_pid = Process.pid

      Signal.trap "SIGTERM" do
        # The worker installs their own SIGTERM when booted.
        # Until then, this is run by the worker and the worker
        # should just exit if they get it.
        if Process.pid != master_pid
          log "Early termination of worker"
          exit! 0
        else
          @launcher.close_binder_listeners

          stop_workers
          stop

          raise(SignalException, "SIGTERM") if @options[:raise_exception_on_sigterm]
          exit 0 # Clean exit, workers were stopped
        end
      end
    end

    def run
      @status = :run

      output_header "cluster"

      log "* Process workers: #{@options[:workers]}"

      before = Thread.list

      if preload?
        log "* Preloading application"
        load_and_bind

        after = Thread.list

        if after.size > before.size
          threads = (after - before)
          if threads.first.respond_to? :backtrace
            log "! WARNING: Detected #{after.size-before.size} Thread(s) started in app boot:"
            threads.each do |t|
              log "! #{t.inspect} - #{t.backtrace ? t.backtrace.first : ''}"
            end
          else
            log "! WARNING: Detected #{after.size-before.size} Thread(s) started in app boot"
          end
        end
      else
        log "* Phased restart available"

        unless @launcher.config.app_configured?
          error "No application configured, nothing to run"
          exit 1
        end

        @launcher.binder.parse @options[:binds], self
      end

      read, @wakeup = Puma::Util.pipe

      setup_signals

      # Used by the workers to detect if the master process dies.
      # If select says that @check_pipe is ready, it's because the
      # master has exited and @suicide_pipe has been automatically
      # closed.
      #
      @check_pipe, @suicide_pipe = Puma::Util.pipe

      # Separate pipe used by worker 0 to receive commands to
      # fork new worker processes.
      @fork_pipe, @fork_writer = Puma::Util.pipe

      log "Use Ctrl-C to stop"

      redirect_io

      Plugins.fire_background

      @launcher.write_state

      start_control

      @master_read, @worker_write = read, @wakeup

      @launcher.config.run_hooks :before_fork, nil, @launcher.events
      nakayoshi_gc

      spawn_workers

      Signal.trap "SIGINT" do
        stop
      end

      @launcher.events.fire_on_booted!

      begin
        while @status == :run
          begin
            if @phased_restart
              start_phased_restart
              @phased_restart = false
            end

            check_workers

            res = IO.select([read], nil, nil, [0, @next_check - Time.now].max)

            if res
              req = read.read_nonblock(1)

              @next_check = Time.now if req == "!"
              next if !req || req == "!"

              result = read.gets
              pid = result.to_i

              if req == "b" || req == "f"
                pid, idx = result.split(':').map(&:to_i)
                w = @workers.find {|x| x.index == idx}
                w.pid = pid if w.pid.nil?
              end

              if w = @workers.find { |x| x.pid == pid }
                case req
                when "b"
                  w.boot!
                  log "- Worker #{w.index} (pid: #{pid}) booted, phase: #{w.phase}"
                  @next_check = Time.now
                when "e"
                  # external term, see worker method, Signal.trap "SIGTERM"
                  w.instance_variable_set :@term, true
                when "t"
                  w.term unless w.term?
                when "p"
                  w.ping!(result.sub(/^\d+/,'').chomp)
                  @launcher.events.fire(:ping!, w)
                end
              else
                log "! Out-of-sync worker list, no #{pid} worker"
              end
            end

          rescue Interrupt
            @status = :stop
          end
        end

        stop_workers unless @status == :halt
      ensure
        @check_pipe.close
        @suicide_pipe.close
        read.close
        @wakeup.close
      end
    end

    private

    # loops thru @workers, removing workers that exited, and calling
    # `#term` if needed
    def wait_workers
      @workers.reject! do |w|
        next false if w.pid.nil?
        begin
          if Process.wait(w.pid, Process::WNOHANG)
            true
          else
            w.term if w.term?
            nil
          end
        rescue Errno::ECHILD
          begin
            Process.kill(0, w.pid)
            false # child still alive, but has another parent
          rescue Errno::ESRCH, Errno::EPERM
            true # child is already terminated
          end
        end
      end
    end

    # @version 5.0.0
    def timeout_workers
      @workers.each do |w|
        if !w.term? && w.ping_timeout <= Time.now
          log "! Terminating timed out worker: #{w.pid}"
          w.kill
        end
      end
    end

    # @version 5.0.0
    def nakayoshi_gc
      return unless @options[:nakayoshi_fork]
      log "! Promoting existing objects to old generation..."
      4.times { GC.start(full_mark: false) }
      if GC.respond_to?(:compact)
        log "! Compacting..."
        GC.compact
      end
      log "! Friendly fork preparation complete."
    end
  end
end
