# -*- encoding: binary -*-

# :enddoc:
$stdout.sync = $stderr.sync = true
$stdin.binmode
$stdout.binmode
$stderr.binmode

require 'unicorn'

module Unicorn::Launcher

  # We don't do a lot of standard daemonization stuff:
  #   * umask is whatever was set by the parent process at startup
  #     and can be set in config.ru and config_file, so making it
  #     0000 and potentially exposing sensitive log data can be bad
  #     policy.
  #   * don't bother to chdir("/") here since unicorn is designed to
  #     run inside APP_ROOT.  Unicorn will also re-chdir() to
  #     the directory it was started in when being re-executed
  #     to pickup code changes if the original deployment directory
  #     is a symlink or otherwise got replaced.
  def self.daemonize!(options)
    cfg = Unicorn::Configurator
    $stdin.reopen("/dev/null")

    # We only start a new process group if we're not being reexecuted
    # and inheriting file descriptors from our parent
    unless ENV['UNICORN_FD']
      # grandparent - reads pipe, exits when master is ready
      #  \_ parent  - exits immediately ASAP
      #      \_ unicorn master - writes to pipe when ready

      rd, wr = Unicorn.pipe
      grandparent = $$
      if fork
        wr.close # grandparent does not write
      else
        rd.close # unicorn master does not read
        Process.setsid
        exit if fork # parent dies now
      end

      if grandparent == $$
        # this will block until HttpServer#join runs (or it dies)
        master_pid = (rd.readpartial(16) rescue nil).to_i
        unless master_pid > 1
          warn "master failed to start, check stderr log for details"
          exit!(1)
        end
        exit 0
      else # unicorn master process
        options[:ready_pipe] = wr
      end
    end
    # $stderr/$stderr can/will be redirected separately in the Unicorn config
    cfg::DEFAULTS[:stderr_path] ||= "/dev/null"
    cfg::DEFAULTS[:stdout_path] ||= "/dev/null"
    cfg::RACKUP[:daemonized] = true
  end

end
