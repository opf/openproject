#!/usr/bin/ruby
# -*- encoding: binary -*-
$stdout.sync = $stderr.sync = true
# this is used to show or watch the number of active and queued
# connections on any listener socket from the command line

require 'raindrops'
require 'optparse'
require 'ipaddr'
require 'time'
begin
  require 'sleepy_penguin'
rescue LoadError
end
usage = "Usage: #$0 [-d DELAY] [-t QUEUED_THRESHOLD] ADDR..."
ARGV.size > 0 or abort usage
delay = false
queued_thresh = -1
# "normal" exits when driven on the command-line
trap(:INT) { exit 130 }
trap(:PIPE) { exit 0 }

OptionParser.new('', 24, '  ') do |opts|
  opts.banner = usage
  opts.on('-d', '--delay=DELAY', Float) { |n| delay = n }
  opts.on('-t', '--queued-threshold=INT', Integer) { |n| queued_thresh = n }
  opts.on('-a', '--all') { } # noop
  opts.parse! ARGV
end

begin
  require 'aggregate'
rescue LoadError
  $stderr.puts "Aggregate missing, USR1 and USR2 handlers unavailable"
end if delay

if delay && defined?(SleepyPenguin::TimerFD)
  @tfd = SleepyPenguin::TimerFD.new
  @tfd.settime nil, delay, delay
  def delay_for(seconds)
    @tfd.expirations
  end
else
  alias delay_for sleep
end

agg_active = agg_queued = nil
if delay && defined?(Aggregate)
  agg_active = Aggregate.new
  agg_queued = Aggregate.new

  def dump_aggregate(label, agg)
    $stderr.write "--- #{label} ---\n"
    %w(count min max outliers_low outliers_high mean std_dev).each do |f|
      $stderr.write "#{f}=#{agg.__send__ f}\n"
    end
    $stderr.write "#{agg}\n\n"
  end

  trap(:USR1) do
    dump_aggregate "active", agg_active
    dump_aggregate "queued", agg_queued
  end
  trap(:USR2) do
    agg_active = Aggregate.new
    agg_queued = Aggregate.new
  end
  $stderr.puts "USR1(dump_aggregate) and USR2(reset) handlers ready for PID=#$$"
end

ARGV.each do |addr|
  addr =~ %r{\A(127\..+):(\d+)\z} or next
  host, port = $1, $2
  hex_port = '%X' % port.to_i
  ip_addr = IPAddr.new(host)
  hex_host = ip_addr.hton.each_byte.inject('') { |s,o| s << '%02X' % o }
  socks = File.readlines('/proc/net/tcp')
  hex_addr = "#{hex_host}:#{hex_port}"
  if socks.grep(/^\s+\d+:\s+#{hex_addr}\s+/).empty? &&
     ! socks.grep(/^\s+\d+:\s+00000000:#{hex_port}\s+/).empty?
    warn "W: #{host}:#{port} (#{hex_addr}) not found in /proc/net/tcp"
    warn "W: Did you mean 0.0.0.0:#{port}?"
  end
end

len = "address".size
now = nil
tcp, unix = [], []
ARGV.each do |addr|
  bs = addr.respond_to?(:bytesize) ? addr.bytesize : addr.size
  len = bs if bs > len
  (addr =~ %r{\A/} ? unix : tcp) << addr
end
combined = {}
tcp_args = unix_args = nil
unless tcp.empty? && unix.empty?
  tcp_args = tcp
  unix_args = unix
end
sock = Raindrops::InetDiagSocket.new if tcp

len = 35 if len > 35
fmt = "%20s % #{len}s % 10u % 10u\n"
$stderr.printf fmt.tr('u','s'), *%w(timestamp address active queued)

begin
  if now
    combined.clear
    now = nil
  end
  combined.merge! Raindrops::Linux.tcp_listener_stats(tcp_args, sock)
  combined.merge! Raindrops::Linux.unix_listener_stats(unix_args)
  combined.each do |addr,stats|
    active, queued = stats.active, stats.queued
    if agg_active
      agg_active << active
      agg_queued << queued
    end
    next if queued < queued_thresh
    printf fmt, now ||= Time.now.utc.iso8601, addr, active, queued
  end
end while delay && delay_for(delay)
