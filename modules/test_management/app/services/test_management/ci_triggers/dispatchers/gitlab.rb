# frozen_string_literal: true

module TestManagement
  module CiTriggers
    module Dispatchers
      # GitLab pipeline trigger:
      #   POST {base}/api/v4/projects/{url-encoded path}/trigger/pipeline
      #   token=<trigger token>&ref=main&variables[OP_RUN_ID]=…
      # Answers 201 with the pipeline (id, web_url). CI/CD variables work on every GitLab
      # version (pipeline "inputs" would need 17.11+).
      # https://docs.gitlab.com/api/pipeline_triggers/
      class Gitlab < Base
        protected

        def dispatch(ref:, inputs:)
          url = "#{base_url}/api/v4/projects/#{enc(repository)}/trigger/pipeline"
          form = { "token" => connection.decrypted_trigger_token, "ref" => ref }
          variables(inputs).each { |key, value| form["variables[#{key}]"] = value }
          response = post(url, form:)
          return http_failure(response) unless (200..299).cover?(code(response))

          pipeline = json(response)
          triggered(url: pipeline["web_url"] || "#{base_url}/#{repository}/-/pipelines", external_id: pipeline["id"])
        end
      end
    end
  end
end
