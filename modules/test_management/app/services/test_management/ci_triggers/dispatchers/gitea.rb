# frozen_string_literal: true

module TestManagement
  module CiTriggers
    module Dispatchers
      # Gitea Actions workflow_dispatch (API since Gitea 1.24):
      #   POST {base}/api/v1/repos/{owner}/{repo}/actions/workflows/{workflow file}/dispatches?return_run_details=true
      #   {"ref": "refs/heads/main", "inputs": {...}}   (input values are strings)
      # Gitea 1.26+ answers 200 with workflow_run_id / html_url; 1.24 / 1.25 answer 204.
      # Token scope write:repository, header "Authorization: token …".
      # https://docs.gitea.com/api/1.26/operations/actions-dispatch-workflow/
      class Gitea < Base
        protected

        def dispatch(ref:, inputs:)
          response = post(dispatch_url, json: body(ref, inputs), headers: { "Authorization" => "token #{token}" })
          handle(response)
        end

        def dispatch_url
          "#{base_url}/api/v1/repos/#{repository}/actions/workflows/#{enc(connection.workflow)}/dispatches" \
            "?return_run_details=true"
        end

        def body(ref, inputs)
          { ref: full_ref(ref), inputs: }
        end

        # A short name is sent as a branch ("main" -> "refs/heads/main"); a full ref
        # ("refs/tags/v1.2") is sent unchanged.
        def full_ref(ref)
          ref.start_with?("refs/") ? ref : "refs/heads/#{ref}"
        end

        def handle(response)
          case code(response)
          when 200
            details = json(response)
            triggered(url: details["html_url"] || workflow_url, external_id: details["workflow_run_id"])
          when 201, 204 then triggered(url: workflow_url)
          else http_failure(response)
          end
        end

        def workflow_url = "#{base_url}/#{repository}/actions?workflow=#{enc(connection.workflow)}"
      end
    end
  end
end
