module OkComputer
  # This class provides a check for a mongodb replica set via the Mongoid ORM.
  #
  # The check first refreshes the cluster status, which communicates with all
  # the nodes, discovers any new ones, and figures out which node is the
  # primary and which ones are the secondaries. Nodes that are recovering or
  # unavailable are automatically removed from rotation. It's okay to do this
  # fairly frequently.
  #
  # The second part of the check attempts to contact the primary node (to
  # ensure writes are accepted) and a secondary node (to ensure reads
  # can be distributed).
  #
  # This calls the
  # {replSetGetStatus}[http://docs.mongodb.org/manual/reference/command/replSetGetStatus/]
  # command on the admin database of each node. This provides further
  # information as well as the replica set's name. This could potentially be
  # parsed for more actionable information.
  class MongoidReplicaSetCheck < OkComputer::Check
    attr_accessor :session

    # Public: Initialize a check for a Mongoid replica set
    #
    # session - The name of the Mongoid session to use. Defaults to the
    #   default session.
    def initialize(session = :default)
      self.session = Mongoid::Sessions.with_name(session)
    rescue => e
      # client/session not configured
    end

    # Public: Return the status of the mongodb replica set
    def check
      refresh
      primary_status = self.primary_status
      secondary_status = self.secondary_status
      mark_message "Connected to #{session.cluster.nodes.count} nodes in mongodb replica set '#{primary_status['set']}'"
    rescue ConnectionFailed => e
      mark_failure
      mark_message "Error: '#{e}'"
    end

    # Public: Refresh the cluster status
    def refresh
      session.cluster.refresh
    rescue => e
      raise ConnectionFailed, e
    end

    # Public: The status for the session's mongodb replica set primary
    #
    # Returns a hash with the status of the primary
    def primary_status
      session.cluster.with_primary do |primary|
        primary.command(:admin, replSetGetStatus: 1)
      end
    rescue => e
      raise ConnectionFailed, e
    end

    # Public: The status for the session's mongodb replica set secondary
    #
    # Returns a hash with the status of the secondary
    def secondary_status
      session.cluster.with_secondary do |secondary|
        secondary.command(:admin, replSetGetStatus: 1)
      end
    rescue => e
      raise ConnectionFailed, e
    end

    ConnectionFailed = Class.new(StandardError)
  end
end
