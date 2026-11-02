# frozen_string_literal: true

module TestManagement
  module CiTriggers
    # What to run by hand for a "Run in CI" on an inbound-only connection (0015): the CI
    # variables and one copyable command that starts the pipeline from inside the network
    # (OpenProject itself never calls the server). Secrets are placeholders ($GITLAB_TRIGGER_TOKEN,
    # $CI_TOKEN, …) – OpenProject does not render stored tokens.
    #
    #   GitLab                  curl … /api/v4/projects/:path/trigger/pipeline (trigger token)
    #   GitHub                  gh workflow run <workflow> --ref <ref> -f op_run_id=…
    #   Gitea / Forgejo         curl … /api/v1/repos/:repo/actions/workflows/:workflow/dispatches
    #   Jenkins                 curl … <job>/buildWithParameters
    #   Woodpecker              curl … /api/repos/:id/pipelines
    # The connection's CA (if any) is referenced as --cacert ./ca.pem.
    class ManualStart
      SAFE_WORD = %r{\A[A-Za-z0-9_@%+=:,./-]+\z}

      attr_reader :connection, :run, :iteration, :op_url

      def initialize(connection:, run:, iteration:, op_url:)
        @connection = connection
        @run = run
        @iteration = iteration
        @op_url = op_url.to_s.chomp("/")
      end

      def trigger
        @trigger ||= Hash(iteration&.ci_info&.dig("trigger"))
      end

      def ref
        trigger["ref"].presence || connection.effective_trigger_ref
      end

      def grep
        trigger["grep"].to_s
      end

      # Upper-case CI variables (GitLab, Jenkins, Woodpecker; also what op-tm-upload.sh reads).
      def variables
        {
          "OP_URL" => op_url,
          "OP_PROJECT" => run.project.identifier,
          "OP_CONNECTION" => connection.name,
          "OP_RUN_ID" => run.id.to_s,
          "OP_ITERATION_ID" => iteration.id.to_s,
          "OP_GREP" => grep
        }
      end

      # workflow_dispatch inputs (GitHub, Gitea, Forgejo, Codeberg).
      def inputs
        {
          "op_run_id" => run.id.to_s, "op_iteration_id" => iteration.id.to_s,
          "op_project" => run.project.identifier, "op_grep" => grep
        }
      end

      def variables_text
        variables.map { |key, value| "#{key}=#{shell_quote(value)}" }.join("\n")
      end

      def command
        case connection.provider
        when "gitlab" then gitlab
        when "github" then github
        when "jenkins" then jenkins
        when "woodpecker" then woodpecker
        else gitea
        end
      end

      # POSIX shell quoting that stays readable: plain words as they are, everything else in single
      # quotes ('it'\''s'). Safe for any value; URLs and "variables[KEY]=value" remain copyable.
      def shell_quote(value)
        value = value.to_s
        return "''" if value.empty?
        return value if value.match?(SAFE_WORD)

        "'#{value.gsub("'") { "'\\''" }}'"
      end

      private

      def base = connection.effective_base_url
      def esc(value) = shell_quote(value)
      def enc(value) = ERB::Util.url_encode(value.to_s)

      def curl
        ["curl --fail --silent --show-error", ("--cacert ./ca.pem" if connection.ca_certificate.present?)].compact.join(" ")
      end

      def pipeline_variables
        variables.except("OP_URL", "OP_CONNECTION")
      end

      def gitlab
        lines = ["#{curl} --request POST", "--form token=\"$GITLAB_TRIGGER_TOKEN\"", "--form ref=#{esc(ref)}"]
        pipeline_variables.each { |key, value| lines << "--form #{esc("variables[#{key}]=#{value}")}" }
        lines << esc("#{base}/api/v4/projects/#{enc(connection.repository)}/trigger/pipeline")
        lines.join(" \\\n  ")
      end

      def github
        host = URI.parse(base).host
        prefix = host == "github.com" ? "" : "GH_HOST=#{esc(host)} "
        lines = ["#{prefix}gh workflow run #{esc(connection.workflow || 'op-tests.yml')}",
                 "--repo #{esc(connection.repository)}", "--ref #{esc(ref)}"]
        inputs.each { |key, value| lines << "-f #{esc("#{key}=#{value}")}" }
        lines.join(" \\\n  ")
      end

      def gitea
        full_ref = ref.start_with?("refs/") ? ref : "refs/heads/#{ref}"
        body = { ref: full_ref, inputs: }.to_json
        url = "#{base}/api/v1/repos/#{connection.repository}/actions/workflows/#{enc(connection.workflow || 'op-tests.yml')}/dispatches"
        ["#{curl} --request POST", "--header \"Authorization: token $CI_TOKEN\"",
         "--header 'Content-Type: application/json'", "--data #{esc(body)}", esc(url)].join(" \\\n  ")
      end

      def jenkins
        user = connection.ci_username.present? ? esc(connection.ci_username) : "\"$JENKINS_USER\""
        lines = ["#{curl} --request POST", "--user #{user}:\"$JENKINS_API_TOKEN\""]
        pipeline_variables.merge("OP_REF" => ref).each { |key, value| lines << "--data-urlencode #{esc("#{key}=#{value}")}" }
        lines << esc("#{connection.jenkins_job_url}/buildWithParameters")
        lines.join(" \\\n  ")
      end

      def woodpecker
        body = { branch: ref, variables: pipeline_variables }.to_json
        ["#{curl} --request POST", "--header \"Authorization: Bearer $WOODPECKER_TOKEN\"",
         "--header 'Content-Type: application/json'", "--data #{esc(body)}",
         esc("#{base}/api/repos/#{enc(connection.repository)}/pipelines")].join(" \\\n  ")
      end
    end
  end
end
