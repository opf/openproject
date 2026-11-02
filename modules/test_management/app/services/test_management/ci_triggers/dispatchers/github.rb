# frozen_string_literal: true

module TestManagement
  module CiTriggers
    module Dispatchers
      # GitHub Actions workflow_dispatch:
      #   POST {api}/repos/{owner}/{repo}/actions/workflows/{workflow file}/dispatches
      #   {"ref": "main", "inputs": {...}}   (max. 25 inputs; the workflow must declare them)
      # api.github.com: return_run_details=true answers 200 with workflow_run_id / html_url
      # (2026-02-19 changelog). GitHub Enterprise Server may not know the flag, so it is only
      # sent to github.com; 204 (no run details) is accepted everywhere.
      # https://docs.github.com/en/rest/actions/workflows#create-a-workflow-dispatch-event
      class Github < Base
        protected

        def dispatch(ref:, inputs:)
          api = TestManagement::CiConnections::CheckService.github_api(base_url)
          url = "#{api}/repos/#{repository}/actions/workflows/#{enc(connection.workflow)}/dispatches"
          body = { ref:, inputs: }
          body[:return_run_details] = true if api == "https://api.github.com"
          response = post(url, json: body, headers: { "Authorization" => "Bearer #{token}",
                                                      "Accept" => "application/vnd.github+json" })
          case code(response)
          when 200
            details = json(response)
            triggered(url: details["html_url"] || workflow_url, external_id: details["workflow_run_id"])
          when 204 then triggered(url: workflow_url)
          else http_failure(response)
          end
        end

        private

        def workflow_url = "#{base_url}/#{repository}/actions/workflows/#{enc(connection.workflow)}"
      end
    end
  end
end
