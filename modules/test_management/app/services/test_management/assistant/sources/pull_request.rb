# frozen_string_literal: true

module TestManagement
  module Assistant
    module Sources
      # Title, description and diff of a pull/merge request of a repository that one of the
      # project's CI connections points at (Project settings > Test management > CI connections).
      #
      # * Only URLs under a connection's repository URL are accepted; the request goes to that
      #   connection's API base (never to a host taken from the pasted URL), with its token.
      # * Requests use OpenProject.httpx (SSRF filter) with the connection's CA
      #   (CiConnections::Http), a 20 s timeout, refuse bodies above MAX_BYTES, and the diff is
      #   cut to DIFF_CHARS characters for the prompt.
      # * Self-hosted servers (0015): the repository URL includes the base URL's path, so
      #   https://host/gitlab/group/app/-/merge_requests/7 matches a connection with base URL
      #   https://host/gitlab. Inbound-only connections are recognized but never called.
      #
      #   GitHub   …/owner/repo/pull/12          GET /repos/owner/repo/pulls/12 (+ Accept: …diff)
      #   GitLab   …/group/project/-/merge_requests/12
      #                                          GET /api/v4/projects/:path/merge_requests/12(/diffs)
      #            /diffs needs GitLab 15.7+; older servers answer 404 and /changes is used instead.
      #   Gitea, Forgejo, Codeberg …/owner/repo/pulls/12
      #                                          GET /api/v1/repos/owner/repo/pulls/12(.diff)
      class PullRequest
        PROVIDERS = %w[github gitlab gitea forgejo codeberg].freeze
        TIMEOUT_SECONDS = 20
        MAX_BYTES = 2_000_000
        DIFF_CHARS = 40_000
        BODY_CHARS = 10_000
        MAX_GITLAB_DIFF_FILES = 100

        # HTTP 404 (still an Error for callers; lets GitLab fall back from /diffs to /changes).
        class NotFound < Error; end

        attr_reader :project, :url

        def initialize(project:, url:)
          @project = project
          @url = self.class.normalize(url)
        end

        def self.normalize(url)
          url.to_s.strip.sub(/[#?].*\z/, "").chomp("/").sub(%r{/(files|commits|diffs|changes)\z}, "")
        end

        # [connection, number] or nil
        def match
          return @match if defined?(@match)

          @match = connections.lazy.filter_map do |connection|
            prefix = connection.repository_url.chomp("/")
            next unless url.downcase.start_with?("#{prefix.downcase}/")

            rest = url[(prefix.length + 1)..]
            number = case connection.provider
                     when "github" then rest[%r{\Apull/(\d+)\z}, 1]
                     when "gitlab" then rest[%r{\A(?:-/)?merge_requests/(\d+)\z}, 1]
                     else rest[%r{\Apulls/(\d+)\z}, 1]
                     end
            [connection, number.to_i] if number
          end.first
        end

        def connections
          ::TestManagement::CiConnection.where(project_id: project.id, provider: PROVIDERS).order(:id).to_a
        end

        def material
          connection, number = match
          raise Error, I18n.t("test_management.assistant.errors.pull_request_unknown") unless connection
          if connection.inbound_only?
            raise Error, I18n.t("test_management.assistant.errors.pull_request_inbound_only", connection: connection.name)
          end

          info, diff = fetch(connection, number)
          text = ["Pull request: #{info[:title]}", "URL: #{url}"]
          text << "Description:\n#{Prompt.truncate(info[:body].to_s, BODY_CHARS)}" if info[:body].present?
          text << "Diff:\n#{Prompt.truncate(diff.to_s, DIFF_CHARS)}" if diff.present?
          Material.new(label: "Pull request", text: text.join("\n\n"))
        end

        private

        def fetch(connection, number)
          base = connection.effective_base_url
          repo = connection.repository
          case connection.provider
          when "github"
            api = "#{CiConnections::CheckService.github_api(base)}/repos/#{repo}/pulls/#{number}"
            info = json(get(connection, api))
            diff = get(connection, api, accept: "application/vnd.github.diff").body.to_s
            [{ title: info["title"], body: info["body"] }, diff]
          when "gitlab"
            api = "#{base}/api/v4/projects/#{ERB::Util.url_encode(repo)}/merge_requests/#{number}"
            info = json(get(connection, api))
            diff = Array(gitlab_diff_files(connection, api)).first(MAX_GITLAB_DIFF_FILES).filter_map do |file|
              next unless file.is_a?(Hash)

              "--- #{file['old_path']}\n+++ #{file['new_path']}\n#{file['diff']}"
            end.join("\n")
            [{ title: info["title"], body: info["description"] }, diff]
          else
            api = "#{base}/api/v1/repos/#{repo}/pulls/#{number}"
            info = json(get(connection, api))
            diff = get(connection, "#{api}.diff", accept: "text/plain").body.to_s
            [{ title: info["title"], body: info["body"] }, diff]
          end
        end

        # GET …/diffs (GitLab 15.7+); a 404 there on an older server -> deprecated GET …/changes.
        def gitlab_diff_files(connection, api)
          json(get(connection, "#{api}/diffs?per_page=#{MAX_GITLAB_DIFF_FILES}"), array: true)
        rescue NotFound
          changes = json(get(connection, "#{api}/changes"))
          changes["changes"]
        end

        def get(connection, target, accept: nil)
          headers = request_headers(connection)
          headers["Accept"] = accept if accept
          response = begin
            CiConnections::Http.session(connection, timeout: TIMEOUT_SECONDS).get(target, headers:)
          rescue StandardError => e
            raise Error, failure(connection, CiConnections::Http.describe(e, connection))
          end
          if CiConnections::Http.error_response?(response)
            raise Error, failure(connection, CiConnections::Http.describe(response.error, connection))
          end

          if Array(response.headers["content-length"]).first.to_i > MAX_BYTES
            raise Error, failure(connection, I18n.t("test_management.assistant.errors.response_too_large"))
          end

          status = response.status.to_i
          raise NotFound, failure(connection, "HTTP #{status}") if status == 404
          raise Error, failure(connection, "HTTP #{status}") unless status.between?(200, 299)

          body = response.body.to_s
          if body.bytesize > MAX_BYTES
            raise Error,
                  failure(connection, I18n.t("test_management.assistant.errors.response_too_large"))
          end

          response
        end

        def request_headers(connection)
          token = connection.decrypted_token
          common = { "User-Agent" => "OpenProject-TestManagement", "Accept" => "application/json" }
          return common if token.blank?

          CiConnections::CheckService.new(user: User.current, connection:).headers(token)
        end

        def json(response, array: false)
          parsed = JSON.parse(response.body.to_s)
          if array
            parsed
          else
            (parsed.is_a?(Hash) ? parsed : {})
          end
        rescue JSON::ParserError
          array ? [] : {}
        end

        def failure(connection, detail)
          message = "#{connection.name} (#{connection.provider}): #{detail}"
          token = connection.decrypted_token
          token.present? ? message.gsub(token, "[FILTERED]") : message
        end
      end
    end
  end
end
