# frozen_string_literal: true

module TestManagement
  module CiTriggers
    module Dispatchers
      # Woodpecker manual pipeline:
      #   POST {base}/api/repos/{repo_id}/pipelines   {"branch": "main", "variables": {"OP_RUN_ID": …}}
      # Bearer personal access token. Answers 200 with the pipeline (number). The pipeline
      # runs with event "manual"; the variables are available as environment variables.
      # https://woodpecker-ci.org/api
      class Woodpecker < Base
        protected

        def dispatch(ref:, inputs:)
          url = "#{base_url}/api/repos/#{enc(repository)}/pipelines"
          response = post(url, json: { branch: ref, variables: variables(inputs) },
                               headers: { "Authorization" => "Bearer #{token}" })
          return http_failure(response) unless (200..299).cover?(code(response))

          pipeline = json(response)
          url = pipeline["number"].present? ? "#{base_url}/repos/#{repository}/pipeline/#{pipeline['number']}" : nil
          triggered(url: url || connection.repository_url, external_id: pipeline["number"] || pipeline["id"])
        end
      end
    end
  end
end
