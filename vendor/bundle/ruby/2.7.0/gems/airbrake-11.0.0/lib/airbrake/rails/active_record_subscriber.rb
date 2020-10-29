# frozen_string_literal: true

require 'airbrake/rails/event'
require 'airbrake/rails/backtrace_cleaner'

module Airbrake
  module Rails
    # ActiveRecordSubscriber sends SQL information, including performance data.
    #
    # @since v8.1.0
    class ActiveRecordSubscriber
      def call(*args)
        return unless Airbrake::Config.instance.query_stats

        routes = Airbrake::Rack::RequestStore[:routes]
        return if !routes || routes.none?

        event = Airbrake::Rails::Event.new(*args)
        frame = last_caller

        routes.each do |route, params|
          Airbrake.notify_query(
            route: route,
            method: params[:method],
            query: event.sql,
            func: frame[:function],
            file: frame[:file],
            line: frame[:line],
            timing: event.duration,
            time: event.time,
          )
        end
      end

      private

      def last_caller
        exception = StandardError.new
        exception.set_backtrace(
          Airbrake::Rails::BacktraceCleaner.clean(Kernel.caller),
        )
        Airbrake::Backtrace.parse(exception).first || {}
      end
    end
  end
end
