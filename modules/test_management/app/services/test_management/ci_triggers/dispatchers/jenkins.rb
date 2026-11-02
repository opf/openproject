# frozen_string_literal: true

module TestManagement
  module CiTriggers
    module Dispatchers
      # Jenkins parameterized build:
      #   POST {job url}/buildWithParameters   form: OP_RUN_ID, OP_ITERATION_ID, OP_PROJECT, OP_GREP
      #   (+ token=<build token> when "Trigger builds remotely" is configured)
      # Auth: HTTP Basic user:API token. Requests authenticated with an API token do not need a
      # CSRF crumb; if Jenkins still answers 403, the crumb is fetched from
      # /crumbIssuer/api/json (with the same session cookie) and the request retried once.
      # Jenkins queues the build; the queue item URL (Location header) is kept as reference.
      # https://www.jenkins.io/doc/book/using/remote-access-api/
      # https://www.jenkins.io/doc/book/security/csrf-protection/
      class Jenkins < Base
        protected

        def dispatch(ref:, inputs:)
          url = "#{connection.jenkins_job_url}/buildWithParameters"
          form = variables(inputs).merge("OP_REF" => ref)
          build_token = connection.decrypted_trigger_token
          form["token"] = build_token if build_token.present?
          headers = auth_headers

          response = post(url, form:, headers:)
          if code(response) == 403 && headers.any?
            crumb_headers = crumb(headers)
            response = post(url, form:, headers: headers.merge(crumb_headers)) if crumb_headers
          end
          return http_failure(response) unless (200..299).cover?(code(response))

          triggered(url: connection.jenkins_job_url, external_id: safe_url(header(response, "location")))
        end

        private

        def auth_headers
          return {} if connection.ci_username.blank? || token.blank?

          { "Authorization" => basic_auth(connection.ci_username, token) }
        end

        # { "Jenkins-Crumb" => "…", "Cookie" => "JSESSIONID…=…" } or nil
        def crumb(headers)
          response = get("#{base_url}/crumbIssuer/api/json", headers:)
          return nil unless code(response) == 200

          body = json(response)
          return nil if body["crumbRequestField"].blank? || body["crumb"].blank?

          result = { body["crumbRequestField"].to_s => body["crumb"].to_s }
          cookie = header(response, "set-cookie").to_s.split(";").first
          result["Cookie"] = cookie if cookie.present?
          result
        end
      end
    end
  end
end
