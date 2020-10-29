# -*- encoding: binary -*-
require "socket"
#
#
# This module is used to extend TCPServer and Kgio::TCPServer objects
# and aggregate +last_data_recv+ times for all accepted clients. It
# is designed to be used with Raindrops::LastDataRecv Rack application
# but can be easily changed to work with other stats collection devices.
#
# Methods wrapped include:
# - TCPServer#accept
# - TCPServer#accept_nonblock
# - Kgio::TCPServer#kgio_accept
# - Kgio::TCPServer#kgio_tryaccept
module Raindrops::Aggregate::LastDataRecv
  # The integer value of +last_data_recv+ is sent to this object.
  # This is usually a duck type compatible with the \Aggregate class,
  # but can be *anything* that accepts the *<<* method.
  attr_accessor :raindrops_aggregate

  @@default_aggregate = nil

  # By default, this is a Raindrops::Aggregate::PMQ object
  # It may be anything that responds to *<<*
  def self.default_aggregate
    @@default_aggregate ||= Raindrops::Aggregate::PMQ.new
  end

  # Assign any object that responds to *<<*
  def self.default_aggregate=(agg)
    @@default_aggregate = agg
  end

  # automatically extends any TCPServer objects used by Unicorn
  def self.cornify!
    Unicorn::HttpServer::LISTENERS.each do |sock|
      sock.extend(self) if TCPServer === sock
    end
  end

  # each extended object needs to have TCP_DEFER_ACCEPT enabled
  # for accuracy.
  def self.extended(obj)
    obj.raindrops_aggregate = default_aggregate
    # obj.setsockopt Socket::SOL_TCP, tcp_defer_accept = 9, seconds = 60
    obj.setsockopt Socket::SOL_TCP, 9, 60
  end

  # :stopdoc:

  def kgio_tryaccept(*args)
    count! super
  end

  def kgio_accept(*args)
    count! super
  end

  def accept
    count! super
  end

  def accept_nonblock
    count! super
  end

  # :startdoc:

  # The +last_data_recv+ member of Raindrops::TCP_Info can be used to
  # infer the time a client spent in the listen queue before it was
  # accepted.
  #
  # We require TCP_DEFER_ACCEPT on the listen socket for
  # +last_data_recv+ to be accurate
  def count!(io)
    if io
      x = Raindrops::TCP_Info.new(io)
      @raindrops_aggregate << x.last_data_recv
    end
    io
  end
end

