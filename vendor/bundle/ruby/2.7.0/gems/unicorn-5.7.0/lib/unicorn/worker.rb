# -*- encoding: binary -*-
require "raindrops"

# This class and its members can be considered a stable interface
# and will not change in a backwards-incompatible fashion between
# releases of unicorn.  Knowledge of this class is generally not
# not needed for most users of unicorn.
#
# Some users may want to access it in the before_fork/after_fork hooks.
# See the Unicorn::Configurator RDoc for examples.
class Unicorn::Worker
  # :stopdoc:
  attr_accessor :nr, :switched
  attr_reader :to_io # IO.select-compatible
  attr_reader :master

  PER_DROP = Raindrops::PAGE_SIZE / Raindrops::SIZE
  DROPS = []

  def initialize(nr, pipe=nil)
    drop_index = nr / PER_DROP
    @raindrop = DROPS[drop_index] ||= Raindrops.new(PER_DROP)
    @offset = nr % PER_DROP
    @raindrop[@offset] = 0
    @nr = nr
    @switched = false
    @to_io, @master = pipe || Unicorn.pipe
  end

  def atfork_child # :nodoc:
    # we _must_ close in child, parent just holds this open to signal
    @master = @master.close
  end

  # master fakes SIGQUIT using this
  def quit # :nodoc:
    @master = @master.close if @master
  end

  # parent does not read
  def atfork_parent # :nodoc:
    @to_io = @to_io.close
  end

  # call a signal handler immediately without triggering EINTR
  # We do not use the more obvious Process.kill(sig, $$) here since
  # that signal delivery may be deferred.  We want to avoid signal delivery
  # while the Rack app.call is running because some database drivers
  # (e.g. ruby-pg) may cancel pending requests.
  def fake_sig(sig) # :nodoc:
    old_cb = trap(sig, "IGNORE")
    old_cb.call
  ensure
    trap(sig, old_cb)
  end

  # master sends fake signals to children
  def soft_kill(sig) # :nodoc:
    case sig
    when Integer
      signum = sig
    else
      signum = Signal.list[sig.to_s] or
          raise ArgumentError, "BUG: bad signal: #{sig.inspect}"
    end
    # writing and reading 4 bytes on a pipe is atomic on all POSIX platforms
    # Do not care in the odd case the buffer is full, here.
    @master.kgio_trywrite([signum].pack('l'))
  rescue Errno::EPIPE
    # worker will be reaped soon
  end

  # this only runs when the Rack app.call is not running
  # act like a listener
  def kgio_tryaccept # :nodoc:
    case buf = @to_io.kgio_tryread(4)
    when String
      # unpack the buffer and trigger the signal handler
      signum = buf.unpack('l')
      fake_sig(signum[0])
      # keep looping, more signals may be queued
    when nil # EOF: master died, but we are at a safe place to exit
      fake_sig(:QUIT)
    when :wait_readable # keep waiting
      return false
    end while true # loop, as multiple signals may be sent
  end

  # worker objects may be compared to just plain Integers
  def ==(other_nr) # :nodoc:
    @nr == other_nr
  end

  # called in the worker process
  def tick=(value) # :nodoc:
    @raindrop[@offset] = value
  end

  # called in the master process
  def tick # :nodoc:
    @raindrop[@offset]
  end

  # called in both the master (reaping worker) and worker (SIGQUIT handler)
  def close # :nodoc:
    @master.close if @master
    @to_io.close if @to_io
  end

  # :startdoc:

  # In most cases, you should be using the Unicorn::Configurator#user
  # directive instead.  This method should only be used if you need
  # fine-grained control of exactly when you want to change permissions
  # in your after_fork or after_worker_ready hooks, or if you want to
  # use the chroot support.
  #
  # Changes the worker process to the specified +user+ and +group+,
  # and chroots to the current working directory if +chroot+ is set.
  # This is only intended to be called from within the worker
  # process from the +after_fork+ hook.  This should be called in
  # the +after_fork+ hook after any privileged functions need to be
  # run (e.g. to set per-worker CPU affinity, niceness, etc)
  #
  # +group+ can be specified as a string, or as an array of two
  # strings.  If an array of two strings is given, the first string
  # is used as the primary group of the process, and the second is
  # used as the group of the log files.
  #
  # Any and all errors raised within this method will be propagated
  # directly back to the caller (usually the +after_fork+ hook.
  # These errors commonly include ArgumentError for specifying an
  # invalid user/group and Errno::EPERM for insufficient privileges.
  #
  # chroot support is only available in unicorn 5.3.0+
  # user and group switching appeared in unicorn 0.94.0 (2009-11-05)
  def user(user, group = nil, chroot = false)
    # we do not protect the caller, checking Process.euid == 0 is
    # insufficient because modern systems have fine-grained
    # capabilities.  Let the caller handle any and all errors.
    uid = Etc.getpwnam(user).uid

    if group
      if group.is_a?(Array)
        group, log_group = group
        log_gid = Etc.getgrnam(log_group).gid
      end
      gid = Etc.getgrnam(group).gid
      log_gid ||= gid
    end

    Unicorn::Util.chown_logs(uid, log_gid)
    if gid && Process.egid != gid
      Process.initgroups(user, gid)
      Process::GID.change_privilege(gid)
    end
    if chroot
      chroot = Dir.pwd if chroot == true
      Dir.chroot(chroot)
      Dir.chdir('/')
    end
    Process.euid != uid and Process::UID.change_privilege(uid)
    @switched = true
  end
end
