module Airbrake
  # PerformanceBreakdown holds data that shows how much time a request spent
  # doing certaing subtasks such as (DB querying, view rendering, etc).
  #
  # @see Airbrake.notify_breakdown
  # @api public
  # @since v4.2.0
  # rubocop:disable Metrics/ParameterLists
  class PerformanceBreakdown
    include HashKeyable
    include Ignorable
    include Stashable
    include Mergeable

    attr_accessor :method, :route, :response_type, :groups, :timing, :time

    def initialize(
      method:,
      route:,
      response_type:,
      groups:,
      timing: nil,
      time: Time.now
    )
      @time_utc = TimeTruncate.utc_truncate_minutes(time)
      @method = method
      @route = route
      @response_type = response_type
      @groups = groups
      @timing = timing
      @time = time
    end

    def destination
      'routes-breakdowns'
    end

    def cargo
      'routes'
    end

    def to_h
      {
        'method' => method,
        'route' => route,
        'responseType' => response_type,
        'time' => @time_utc,
      }.delete_if { |_key, val| val.nil? }
    end
  end
  # rubocop:enable Metrics/ParameterLists
end
