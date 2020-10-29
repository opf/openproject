# -*- encoding: binary -*-
require "tempfile"
require "aggregate"
require "posix_mq"
require "fcntl"
require "thread"
require "stringio"

# \Aggregate + POSIX message queues support for Ruby 1.9+ and \Linux
#
# This class is duck-type compatible with \Aggregate and allows us to
# aggregate and share statistics from multiple processes/threads aided
# POSIX message queues.  This is designed to be used with the
# Raindrops::LastDataRecv Rack application, but can be used independently
# on compatible Runtimes.
#
# Unlike the core of raindrops, this is only supported on Ruby 1.9+ and
# Linux 2.6+.  Using this class requires the following additional RubyGems
# or libraries:
#
# * aggregate (tested with 0.2.2)
# * posix_mq  (tested with 1.0.0)
#
# == Design
#
# There is one master thread which aggregates statistics.  Individual
# worker processes or threads will write to a shared POSIX message
# queue (default: "/raindrops") that the master reads from.  At a
# predefined interval, the master thread will write out to a shared,
# anonymous temporary file that workers may read from
#
# Setting +:worker_interval+ and +:master_interval+ to +1+ will result
# in perfect accuracy but at the cost of a high synchronization
# overhead.  Larger intervals mean less frequent messaging for higher
# performance but lower accuracy.
class Raindrops::Aggregate::PMQ

  # :stopdoc:
  # These constants are for Linux.  This is designed for aggregating
  # TCP_INFO.
  RDLOCK = [ Fcntl::F_RDLCK ].pack("s @256".freeze).freeze
  WRLOCK = [ Fcntl::F_WRLCK ].pack("s @256".freeze).freeze
  UNLOCK = [ Fcntl::F_UNLCK ].pack("s @256".freeze).freeze
  # :startdoc:

  # returns the number of dropped messages sent to a POSIX message
  # queue if non-blocking operation was desired with :lossy
  attr_reader :nr_dropped

  #
  # Creates a new Raindrops::Aggregate::PMQ object
  #
  #   Raindrops::Aggregate::PMQ.new(options = {})  -> aggregate
  #
  # +options+ is a hash that accepts the following keys:
  #
  # * :queue - name of the POSIX message queue (default: "/raindrops")
  # * :worker_interval - interval to send to the master (default: 10)
  # * :master_interval - interval to for the master to write out (default: 5)
  # * :lossy - workers drop packets if master cannot keep up (default: false)
  # * :aggregate - \Aggregate object (default: \Aggregate.new)
  # * :mq_umask - umask for creatingthe POSIX message queue (default: 0666)
  #
  def initialize(params = {})
    opts = {
      :queue => ENV["RAINDROPS_MQUEUE"] || "/raindrops",
      :worker_interval => 10,
      :master_interval => 5,
      :lossy => false,
      :mq_attr => nil,
      :mq_umask => 0666,
      :aggregate => Aggregate.new,
    }.merge! params
    @master_interval = opts[:master_interval]
    @worker_interval = opts[:worker_interval]
    @aggregate = opts[:aggregate]
    @worker_queue = @worker_interval ? [] : nil
    @mutex = Mutex.new

    @mq_name = opts[:queue]
    mq = POSIX_MQ.new @mq_name, :w, opts[:mq_umask], opts[:mq_attr]
    Tempfile.open("raindrops_pmq") do |t|
      @wr = File.open(t.path, "wb")
      @rd = File.open(t.path, "rb")
    end
    @wr.sync = true
    @cached_aggregate = @aggregate
    flush_master
    @mq_send = if opts[:lossy]
      @nr_dropped = 0
      mq.nonblock = true
      mq.method :trysend
    else
      mq.method :send
    end
  end

  # adds a sample to the underlying \Aggregate object
  def << val
    if q = @worker_queue
      q << val
      if q.size >= @worker_interval
        mq_send(q) or @nr_dropped += 1
        q.clear
      end
    else
      mq_send(val) or @nr_dropped += 1
    end
  end

  def mq_send(val) # :nodoc:
    @cached_aggregate = nil
    @mq_send.call Marshal.dump(val)
  end

  #
  # Starts running a master loop, usually in a dedicated thread or process:
  #
  #   Thread.new { agg.master_loop }
  #
  # Any worker can call +agg.stop_master_loop+ to stop the master loop
  # (possibly causing the thread or process to exit)
  def master_loop
    buf = ""
    a = @aggregate
    nr = 0
    mq = POSIX_MQ.new @mq_name, :r # this one is always blocking
    begin
      if (nr -= 1) < 0
        nr = @master_interval
        flush_master
      end
      mq.shift(buf)
      data = begin
        Marshal.load(buf) or return
      rescue ArgumentError, TypeError
        next
      end
      Array === data ? data.each { |x| a << x } : a << data
    rescue Errno::EINTR
    rescue => e
      warn "Unhandled exception in #{__FILE__}:#{__LINE__}: #{e}"
      break
    end while true
  ensure
    flush_master
  end

  # Loads the last shared \Aggregate from the master thread/process
  def aggregate
    @cached_aggregate ||= begin
      flush
      Marshal.load(synchronize(@rd, RDLOCK) do |rd|
        dst = StringIO.new
        dst.binmode
        IO.copy_stream(rd, dst, rd.size, 0)
        dst.string
      end)
    end
  end

  # Flushes the currently aggregate statistics to a temporary file.
  # There is no need to call this explicitly as +:worker_interval+ defines
  # how frequently your data will be flushed for workers to read.
  def flush_master
    dump = Marshal.dump @aggregate
    synchronize(@wr, WRLOCK) do |wr|
      wr.truncate 0
      wr.rewind
      wr.write(dump)
    end
  end

  # stops the currently running master loop, may be called from any
  # worker thread or process
  def stop_master_loop
    sleep 0.1 until mq_send(false)
  rescue Errno::EINTR
    retry
  end

  def lock! io, type # :nodoc:
    io.fcntl Fcntl::F_SETLKW, type
  rescue Errno::EINTR
    retry
  end

  # we use both a mutex for thread-safety and fcntl lock for process-safety
  def synchronize io, type # :nodoc:
    @mutex.synchronize do
      begin
        type = type.dup
        lock! io, type
        yield io
      ensure
        lock! io, type.replace(UNLOCK)
        type.clear
      end
    end
  end

  # flushes the local queue of the worker process, sending all pending
  # data to the master.  There is no need to call this explicitly as
  # +:worker_interval+ defines how frequently your queue will be flushed
  def flush
    if q = @local_queue && ! q.empty?
      mq_send q
      q.clear
    end
    nil
  end

  # proxy for \Aggregate#count
  def count; aggregate.count; end

  # proxy for \Aggregate#max
  def max; aggregate.max; end

  # proxy for \Aggregate#min
  def min; aggregate.min; end

  # proxy for \Aggregate#sum
  def sum; aggregate.sum; end

  # proxy for \Aggregate#mean
  def mean; aggregate.mean; end

  # proxy for \Aggregate#std_dev
  def std_dev; aggregate.std_dev; end

  # proxy for \Aggregate#outliers_low
  def outliers_low; aggregate.outliers_low; end

  # proxy for \Aggregate#outliers_high
  def outliers_high; aggregate.outliers_high; end

  # proxy for \Aggregate#to_s
  def to_s(*args); aggregate.to_s(*args); end

  # proxy for \Aggregate#each
  def each; aggregate.each { |*args| yield(*args) }; end

  # proxy for \Aggregate#each_nonzero
  def each_nonzero; aggregate.each_nonzero { |*args| yield(*args) }; end
end
