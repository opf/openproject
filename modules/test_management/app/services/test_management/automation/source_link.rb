# frozen_string_literal: true

module TestManagement
  module Automation
    # Link from a test case's automation reference to the test file on the forge (0015). Works for
    # self-hosted servers because the URL is built from the CI connection (base URL with sub-path),
    # never from the reference: references stay host-independent ("tests/login.spec.ts#…"), so the
    # same case matches uploads from gitlab.com, a self-hosted GitLab or a mirror.
    #
    # Connection: the newest iteration of a run containing the case that came from a forge
    # connection (GitHub, GitLab, Gitea, Forgejo, Codeberg) – with the commit it ran on – else the
    # project's only active forge connection (default branch). Jenkins / Woodpecker have no files.
    # Only file-like references get a link: a path with "/" or a known test file extension.
    #
    # Repo-qualified references (0016, "shop:tests/a.spec.ts#…", Automation::Reference): only the
    # connections named "shop" are used (newest run first, else the oldest active forge); no link
    # when none of them has files. A connection with an attached Repositories-module repository
    # links to OpenProject's repository browser when it is not a forge.
    class SourceLink
      FILE_EXTENSIONS = %w[ts tsx js jsx mjs cjs py rb java kt cs go php feature robot spec].freeze
      PATH_FORMAT = %r{\A[A-Za-z0-9_@+.\-/]+\z}

      Link = Struct.new(:url, :connection, :ref, keyword_init: true)

      def initialize(test_case)
        @test_case = test_case
      end

      def call
        reference = Reference.parse(test_case.automation_reference, names: CiConnection.reference_names(test_case.project))
        path = self.class.file_path(reference.body)
        return nil unless path

        connection, ref = reference.qualified? ? for_name(reference.name) : (from_runs || only_connection || only_scm)
        return nil unless connection

        url = connection.file_url(path, ref:) || scm_url(connection, path, ref)
        url ? Link.new(url:, connection:, ref: ref || connection.effective_trigger_ref) : nil
      end

      # "tests/login.spec.ts#rejects …" -> "tests/login.spec.ts"; nil for "com.acme.LoginTest#test".
      def self.file_path(reference)
        path = reference.to_s.split("#", 2).first.to_s.strip.delete_prefix("./")
        return nil if path.blank? || path.length > 512 || path.start_with?("/") || path.include?("..")
        return nil unless path.match?(PATH_FORMAT)
        return nil unless path.include?("/") || FILE_EXTENSIONS.include?(File.extname(path).delete_prefix(".").downcase)

        path
      end

      private

      attr_reader :test_case

      def for_name(name)
        named = CiConnection.for_reference_name(test_case.project, name).select { |c| c.active? && linkable?(c) }
        return nil if named.empty?

        from_runs(named.map(&:id)) || [named.find(&:forge?) || named.first, nil]
      end

      # Repository browser links only for users who may browse the repository.
      def scm_url(connection, path, ref)
        return nil unless User.current.allowed_in_project?(:browse_repository, test_case.project)

        connection.scm_file_url(path, ref:)
      end

      def linkable?(connection)
        connection.forge? || connection.scm_repository_id.present?
      end

      def from_runs(connection_ids = nil)
        iteration = TestRunIteration.joins(test_run: :run_cases)
                                    .where(tm_test_run_cases: { test_case_id: test_case.id })
                                    .where(tm_test_runs: { project_id: test_case.project_id })
                                    .where.not(connection_id: nil)
                                    .then { |scope| connection_ids ? scope.where(connection_id: connection_ids) : scope }
                                    .includes(:connection)
                                    .order(id: :desc).limit(10).to_a
                                    .find { |candidate| candidate.connection&.forge? }
        return nil unless iteration

        info = iteration.ci_info
        [iteration.connection, info["commitSha"].presence || info["branch"].presence]
      end

      def only_connection
        forges = CiConnection.where(project_id: test_case.project_id).active.to_a.select(&:forge?)
        forges.one? ? [forges.first, nil] : nil
      end

      def only_scm
        attached = CiConnection.where(project_id: test_case.project_id).active.where.not(scm_repository_id: nil).to_a
        attached.one? ? [attached.first, nil] : nil
      end
    end
  end
end
