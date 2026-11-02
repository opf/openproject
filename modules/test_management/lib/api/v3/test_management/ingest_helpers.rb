# frozen_string_literal: true

module API
  module V3
    module TestManagement
      # Request handling for the automation ingest endpoints. Accepts
      # - multipart/form-data: `file` (the report), `metadata` (JSON, as text or a
      #   file part) and any number of `attachments[]` file parts;
      # - application/json: the options at top level plus the report as
      #   `content` (raw string, e.g. JUnit XML or Cucumber messages NDJSON), `report` (a JSON
      #   report: Playwright JSON, Allure results, Cucumber JSON) or `tests` (native format).
      module IngestHelpers
        REPORT_KEYS = %w[content report tests].freeze

        def allowed_content_types
          %w[application/json application/hal+json multipart/form-data]
        end

        def ingest!(run_id: nil)
          content, options, files = multipart_request? ? multipart_payload : json_payload
          options["runId"] = run_id if run_id
          outcome = ::TestManagement::Automation::IngestService
                      .new(user: current_user, project: @project)
                      .call(content:, options:, files:)
          status(outcome.created_run? ? 201 : 200)
          IngestResultRepresenter.new(outcome, current_user:)
        rescue ::TestManagement::Automation::Error => e
          raise api_error_for(e)
        end

        def api_error_for(error)
          case error.code
          when :bad_request then ::API::Errors::InvalidRequestBody.new(error.message)
          when :forbidden then ::API::Errors::Unauthorized.new(message: error.message)
          when :not_found then ::API::Errors::NotFound.new
          when :conflict then ::API::Errors::Conflict.new(message: error.message)
          when :payload_too_large then PayloadTooLarge.new(error.message)
          else ::API::Errors::UnprocessableContent.new(error.message)
          end
        end

        private

        def multipart_request?
          request.content_type.to_s.start_with?("multipart/form-data")
        end

        def multipart_payload
          file = params[:file]
          raise ::API::Errors::InvalidRequestBody.new("The multipart request needs a 'file' part with the report.") unless upload?(file)

          [read_upload(file), parse_metadata(params[:metadata]), attachment_files]
        end

        # The size limit applies before the body is read and parsed (a multi-GB JSON body
        # would otherwise be held in memory twice).
        def json_payload
          raw = read_limited_body
          body = ::TestManagement::Automation::Parsers::Json.load(raw)
          raise ::API::Errors::InvalidRequestBody.new("The request body must be a JSON object.") unless body.is_a?(Hash)

          options = body.except(*REPORT_KEYS, "metadata").merge(Hash(body["metadata"]))
          [json_report(body), options, []]
        rescue ::TestManagement::Automation::Error => e
          raise api_error_for(e)
        end

        def json_report(body)
          if body["content"].is_a?(String) then body["content"]
          elsif body["report"].is_a?(Hash) || body["report"].is_a?(Array) then body["report"].to_json
          elsif body.key?("tests") then { "tests" => body["tests"] }.to_json
          else
            raise ::API::Errors::InvalidRequestBody.new("Send the report as 'content', 'report' or 'tests'.")
          end
        end

        def parse_metadata(value)
          return {} if value.blank?

          text = upload?(value) ? read_upload(value) : value.to_s
          parsed = ::TestManagement::Automation::Parsers::Json.load(text)
          raise ::API::Errors::InvalidRequestBody.new("'metadata' must be a JSON object.") unless parsed.is_a?(Hash)

          parsed
        rescue ::TestManagement::Automation::Error
          raise ::API::Errors::InvalidRequestBody.new("'metadata' is not valid JSON.")
        end

        def attachment_files
          values = params[:attachments]
          values = values.values if values.is_a?(Hash) && !upload?(values)
          Array.wrap(values).select { |value| upload?(value) }.map do |upload|
            ::OpenProject::Files.build_uploaded_file(upload[:tempfile], upload[:type], file_name: upload[:filename])
          end
        end

        def upload?(value)
          value.respond_to?(:key?) && value.key?(:tempfile)
        end

        def read_limited_body
          max = ::TestManagement::Automation::IngestService::MAX_BYTES
          too_large!(max) if request.content_length.to_i > max

          request.body.rewind
          raw = request.body.read(max + 1).to_s
          too_large!(max) if raw.bytesize > max

          raw.force_encoding(Encoding::UTF_8)
        end

        def too_large!(max)
          raise PayloadTooLarge.new("The report exceeds #{max / 1024 / 1024} MB.")
        end

        def read_upload(upload)
          tempfile = upload[:tempfile]
          max = ::TestManagement::Automation::IngestService::MAX_BYTES
          too_large!(max) if tempfile.size > max

          tempfile.rewind
          tempfile.read.to_s.force_encoding(Encoding::UTF_8)
        end
      end
    end
  end
end
