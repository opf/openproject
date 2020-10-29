module Airbrake
  # Request holds request data that powers route stats.
  #
  # @see Airbrake.notify_request
  # @api public
  # @since v3.2.0
  class Request
    include HashKeyable
    include Ignorable
    include Stashable
    include Mergeable
    include Grouppable

    attr_accessor :method, :route, :status_code, :timing, :time

    def initialize(
      method:,
      route:,
      status_code:,
      timing: nil,
      time: Time.now
    )
      @time_utc = TimeTruncate.utc_truncate_minutes(time)
      @method = method
      @route = route
      @status_code = status_code
      @timing = timing
      @time = time
    end

    def destination
      'routes-stats'
    end

    def cargo
      'routes'
    end

    def to_h
      {
        'method' => method,
        'route' => route,
        'statusCode' => status_code,
        'time' => @time_utc,
      }.delete_if { |_key, val| val.nil? }
    end
  end
end
