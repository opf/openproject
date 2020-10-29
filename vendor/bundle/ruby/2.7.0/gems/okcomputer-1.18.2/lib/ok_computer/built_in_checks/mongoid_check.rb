module OkComputer
  class MongoidCheck < Check
    attr_accessor :session

    # Public: Initialize a check for a Mongoid replica set
    #
    # session - The name of the Mongoid session to use. Defaults to the
    #   default session.
    def initialize(session = :default)
      if Mongoid.respond_to?(:clients) # Mongoid 5
        self.session = Mongoid::Clients.with_name(session)
      elsif Mongoid.respond_to?(:sessions) # Mongoid 4
        self.session = Mongoid::Sessions.with_name(session)
      end
    rescue => e
      # client/session not configured
    end

    # Public: Return the status of the mongodb
    def check
      mark_message "Connected to mongodb #{mongodb_name}"
    rescue ConnectionFailed => e
      mark_failure
      mark_message "Error: '#{e}'"
    end

    # Public: The stats for the app's mongodb
    #
    # Returns a hash with the status of the db
    def mongodb_stats
      if session
        stats = session.command(dbStats: 1) # Mongoid 3+
        stats = stats.first unless stats.is_a? Hash # Mongoid 5
        stats
      else
        Mongoid.database.stats # Mongoid 2
      end
    rescue => e
      raise ConnectionFailed, e
    end

    # Public: The name of the app's mongodb
    #
    # Returns a string with the mongdb name
    def mongodb_name
      mongodb_stats["db"]
    end

    ConnectionFailed = Class.new(StandardError)
  end
end
