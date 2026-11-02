# frozen_string_literal: true

module TestManagement
  module Automation
    # Finds the CI connection of an upload:
    # - "connection" option (id or name): that connection, 422 when unknown or inactive;
    # - otherwise auto-detected by ci.provider + ci.repository (inactive ones are ignored); with
    #   ci.serverUrl (0015) only a connection to that server (sub-path included) is used, so an
    #   upload from a self-hosted GitLab does not land on a gitlab.com connection with the same path;
    #   Several connections with that path on different servers (0016) and no serverUrl: the oldest,
    #   with the warning connection_ambiguous;
    # - nil when the project has no matching connection (uploads work without one).
    # The connection provides the defaults for mode / targetRun.
    class ConnectionResolver
      Plan = Struct.new(:connection, :mode, :target_run, keyword_init: true) do
        def new_iteration? = mode == "new_iteration"
      end

      def initialize(project:, options:, warnings: [])
        @project = project
        @options = options
        @warnings = warnings
      end

      def call
        connection = explicit || detected
        Plan.new(connection:,
                 mode: options.mode || connection&.ingest_mode || "new_run",
                 target_run: options.target_run || connection&.target_run_name)
      end

      private

      attr_reader :project, :options, :warnings

      def explicit
        ref = options.connection_ref
        return nil if ref.blank?

        connection = CiConnection.lookup(project, ref)
        raise Error.new(:unprocessable, "Unknown CI connection \"#{ref}\" in this project.") unless connection
        raise Error.new(:unprocessable, "CI connection \"#{connection.name}\" is inactive.") unless connection.active?

        repo = options.ci["repository"]
        if repo.present? && !connection.matches?(options.ci["provider"].presence || connection.provider, repo)
          warnings << { "code" => "connection_repository_mismatch", "connection" => connection.name, "repository" => repo }
        end
        server = options.ci["serverUrl"]
        if CiConnection.server_key(server) && !connection.same_server?(server)
          warnings << { "code" => "connection_server_mismatch", "connection" => connection.name, "serverUrl" => server }
        end
        connection
      end

      def detected
        connection = CiConnection.detect(project, options.ci["provider"], options.ci["repository"],
                                         server_url: options.ci["serverUrl"])
        return nil unless connection

        ambiguity_warning(connection)
        return connection if connection.active?

        warnings << { "code" => "connection_inactive", "connection" => connection.name }
        nil
      end

      # 0016: the same provider + repository may exist on several servers. Without ci.serverUrl the
      # oldest connection is used; the upload says which one, so it can be sent next time.
      def ambiguity_warning(connection)
        return if CiConnection.server_key(options.ci["serverUrl"])

        others = CiConnection.candidates(project, options.ci["provider"], options.ci["repository"]) - [connection]
        return if others.empty?

        warnings << { "code" => "connection_ambiguous", "connection" => connection.name,
                      "others" => others.map(&:name), "hint" => "Send ci.serverUrl to pick the server." }
      end
    end
  end
end
