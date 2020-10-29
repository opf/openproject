# frozen_string_literal: true

module Airbrake
  module Rails
    # This railtie works for any Rails application that supports railties (Rails
    # 3.2+ apps). It makes Airbrake Ruby work with Rails and report errors
    # occurring in the application automatically.
    #
    # rubocop:disable Metrics/BlockLength
    class Railtie < ::Rails::Railtie
      initializer('airbrake.middleware') do |app|
        # Since Rails 3.2 the ActionDispatch::DebugExceptions middleware is
        # responsible for logging exceptions and showing a debugging page in
        # case the request is local. We want to insert our middleware after
        # DebugExceptions, so we don't notify Airbrake about local requests.

        if ::Rails.version.to_i >= 5
          # Avoid the warning about deprecated strings.
          # Insert after DebugExceptions, since ConnectionManagement doesn't
          # exist in Rails 5 anymore.
          app.config.middleware.insert_after(
            ActionDispatch::DebugExceptions,
            Airbrake::Rack::Middleware,
          )
        elsif defined?(::ActiveRecord::ConnectionAdapters::ConnectionManagement)
          # Insert after ConnectionManagement to avoid DB connection leakage:
          # https://github.com/airbrake/airbrake/pull/568
          app.config.middleware.insert_after(
            ::ActiveRecord::ConnectionAdapters::ConnectionManagement,
            'Airbrake::Rack::Middleware',
          )
        else
          # Insert after DebugExceptions for apps without ActiveRecord.
          app.config.middleware.insert_after(
            ActionDispatch::DebugExceptions,
            'Airbrake::Rack::Middleware',
          )
        end
      end

      rake_tasks do
        # Report exceptions occurring in Rake tasks.
        require 'airbrake/rake'

        # Defines tasks such as `airbrake:test` & `airbrake:deploy`.
        require 'airbrake/rake/tasks'
      end

      initializer('airbrake.action_controller') do
        ActiveSupport.on_load(:action_controller, run_once: true) do
          # Patches ActionController with methods that allow us to retrieve
          # interesting request data. Appends that information to notices.
          require 'airbrake/rails/action_controller'
          include Airbrake::Rails::ActionController

          # Cache route information for the duration of the request.
          require 'airbrake/rails/action_controller_route_subscriber'
          ActiveSupport::Notifications.subscribe(
            'start_processing.action_controller',
            Airbrake::Rails::ActionControllerRouteSubscriber.new,
          )

          # Send route stats.
          require 'airbrake/rails/action_controller_notify_subscriber'
          ActiveSupport::Notifications.subscribe(
            'process_action.action_controller',
            Airbrake::Rails::ActionControllerNotifySubscriber.new,
          )

          # Send performance breakdown: where a request spends its time.
          require 'airbrake/rails/action_controller_performance_breakdown_subscriber'
          ActiveSupport::Notifications.subscribe(
            'process_action.action_controller',
            Airbrake::Rails::ActionControllerPerformanceBreakdownSubscriber.new,
          )

          require 'airbrake/rails/net_http' if defined?(Net) && defined?(Net::HTTP)
          require 'airbrake/rails/curb' if defined?(Curl) && defined?(Curl::CURB_VERSION)
          require 'airbrake/rails/http' if defined?(HTTP) && defined?(HTTP::Client)
          require 'airbrake/rails/http_client' if defined?(HTTPClient)
          require 'airbrake/rails/typhoeus' if defined?(Typhoeus)

          if defined?(Excon)
            require 'airbrake/rails/excon_subscriber'
            ActiveSupport::Notifications.subscribe(/excon/, Airbrake::Rails::Excon.new)
            ::Excon.defaults[:instrumentor] = ActiveSupport::Notifications
          end
        end
      end

      initializer('airbrake.active_record') do
        ActiveSupport.on_load(:active_record, run_once: true) do
          # Reports exceptions occurring in some bugged ActiveRecord callbacks.
          # Applicable only to the versions of Rails lower than 4.2.
          if defined?(::Rails) &&
             Gem::Version.new(::Rails.version) <= Gem::Version.new('4.2')
            require 'airbrake/rails/active_record'
            include Airbrake::Rails::ActiveRecord
          end

          if defined?(ActiveRecord)
            # Send SQL queries.
            require 'airbrake/rails/active_record_subscriber'
            ActiveSupport::Notifications.subscribe(
              'sql.active_record', Airbrake::Rails::ActiveRecordSubscriber.new
            )

            # Filter out parameters from SQL body.
            if ::ActiveRecord::Base.respond_to?(:connection_db_config)
              # Rails 6.1+ deprecates "connection_config" in favor of
              # "connection_db_config", so we need an updated call.
              Airbrake.add_performance_filter(
                Airbrake::Filters::SqlFilter.new(
                  ::ActiveRecord::Base.connection_db_config.configuration_hash[:adapter],
                ),
              )
            else
              Airbrake.add_performance_filter(
                Airbrake::Filters::SqlFilter.new(
                  ::ActiveRecord::Base.connection_config[:adapter],
                ),
              )
            end
          end
        end
      end

      initializer('airbrake.active_job') do
        ActiveSupport.on_load(:active_job, run_once: true) do
          # Reports exceptions occurring in ActiveJob jobs.
          require 'airbrake/rails/active_job'
          include Airbrake::Rails::ActiveJob
        end
      end

      initializer('airbrake.action_cable') do
        ActiveSupport.on_load(:action_cable, run_once: true) do
          # Reports exceptions occurring in ActionCable connections.
          require 'airbrake/rails/action_cable'
        end
      end

      runner do
        at_exit do
          Airbrake.notify_sync($ERROR_INFO) if $ERROR_INFO
        end
      end
    end
    # rubocop:enable Metrics/BlockLength
  end
end
