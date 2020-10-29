# -*- encoding: binary -*-

# For reporting TCP ListenStats, users of older \Linux kernels need to ensure
# that the the "inet_diag" and "tcp_diag" kernel modules are loaded as they do
# not autoload correctly.  The inet_diag facilities of \Raindrops is useful
# for periodic snapshot reporting of listen queue sizes.
#
# Instead of snapshotting, Raindrops::Aggregate::LastDataRecv may be used
# to aggregate statistics from +all+ accepted sockets as they arrive
# based on the +last_data_recv+ field in Raindrops::TCP_Info

module Raindrops::Linux

  # The standard proc path for active UNIX domain sockets, feel free to call
  # String#replace on this if your /proc is mounted in a non-standard location
  # for whatever reason
  PROC_NET_UNIX_ARGS = [ '/proc/net/unix', { encoding: "binary" }]

  # Get ListenStats from an array of +paths+
  #
  # Socket state mapping from integer => symbol, based on socket_state
  # enum from include/linux/net.h in the \Linux kernel:
  #     typedef enum {
  #             SS_FREE = 0,              /* not allocated                */
  #             SS_UNCONNECTED,           /* unconnected to any socket    */
  #             SS_CONNECTING,            /* in process of connecting     */
  #             SS_CONNECTED,             /* connected to socket          */
  #             SS_DISCONNECTING          /* in process of disconnecting  */
  #     } socket_state;
  # * SS_CONNECTING maps to ListenStats#queued
  # * SS_CONNECTED maps to ListenStats#active
  #
  # This method may be significantly slower than its tcp_listener_stats
  # counterpart due to the latter being able to use inet_diag via netlink.
  # This parses /proc/net/unix as there is no other (known) way
  # to expose Unix domain socket statistics over netlink.
  def unix_listener_stats(paths = nil)
    rv = Hash.new { |h,k| h[k.freeze] = Raindrops::ListenStats.new(0, 0) }
    if nil == paths
      paths = [ '[^\n]+' ]
    else
      paths = paths.map do |path|
        path = path.dup
        path.force_encoding(Encoding::BINARY)
        if File.symlink?(path)
          link = path
          path = File.readlink(link)
          path.force_encoding(Encoding::BINARY)
          rv[link] = rv[path] # vivify ListenerStats
        else
          rv[path] # vivify ListenerStats
        end
        Regexp.escape(path)
      end
    end
    paths = /^\w+: \d+ \d+ (\d+) \d+ (\d+)\s+\d+ (#{paths.join('|')})$/n

    # no point in pread since we can't stat for size on this file
    File.read(PROC_NET_UNIX_ARGS[0], encoding: 'binary').scan(paths) do |s|
      path = s[-1]
      case s[0]
      when "00000000" # client sockets
        case s[1].to_i
        when 2 then rv[path].queued += 1
        when 3 then rv[path].active += 1
        end
      else
        # listeners, vivify empty stats
        rv[path]
      end
    end

    rv
  end
  module_function :unix_listener_stats

end # Raindrops::Linux
