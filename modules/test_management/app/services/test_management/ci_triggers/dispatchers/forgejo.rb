# frozen_string_literal: true

module TestManagement
  module CiTriggers
    module Dispatchers
      # Forgejo / Codeberg Actions workflow_dispatch (API since Forgejo 8.0):
      #   POST {base}/api/v1/repos/{owner}/{repo}/actions/workflows/{workflow file}/dispatches
      #   {"ref": "refs/heads/main", "inputs": {...}, "return_run_info": true}
      # Forgejo 11.0+ answers 201 with {id, run_number, jobs}; older versions answer 204.
      # Unlike Gitea the flag is in the body and the answer is 201.
      # The ref is sent in full, as for Gitea: Forgejo (8.0+) expands short names itself
      # (git.Repository#ExpandRef) but tries tags before branches, so "main" could hit a tag
      # of the same name. "refs/heads/<branch>" is unambiguous; "refs/tags/…" stays possible.
      # https://forgejo.org/docs/latest/user/actions/reference/ (on.workflow_dispatch)
      class Forgejo < Gitea
        protected

        def dispatch_url
          "#{base_url}/api/v1/repos/#{repository}/actions/workflows/#{enc(connection.workflow)}/dispatches"
        end

        def body(ref, inputs)
          { ref: full_ref(ref), inputs:, return_run_info: true }
        end

        def handle(response)
          case code(response)
          when 201
            run = json(response)
            url = run["run_number"].present? ? "#{base_url}/#{repository}/actions/runs/#{run['run_number']}" : workflow_url
            triggered(url:, external_id: run["id"])
          when 200, 204 then triggered(url: workflow_url)
          else http_failure(response)
          end
        end
      end
    end
  end
end
