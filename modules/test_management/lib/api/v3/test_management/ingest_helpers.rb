# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module API
  module V3
    module TestManagement
      module IngestHelpers
        REPORT_KEYS = %w[content report tests].freeze

        def allowed_content_types
          %w[application/json application/hal+json multipart/form-data]
        end

        def ingest!(run_id: nil)
          content, options = multipart_request? ? multipart_payload : json_payload
          options["runId"] = run_id if run_id
          outcome = ::TestManagement::Automation::IngestService
                      .new(user: current_user, project: @project)
                      .call(content:, options:)
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
          file = params[:report]
          raise ::API::Errors::InvalidRequestBody.new("The multipart request needs a 'report' part.") unless upload?(file)

          [read_upload(file), parse_metadata(params[:metadata])]
        end

        def json_payload
          raw = read_limited_body
          body = ::TestManagement::Automation::Parsers::Json.load(raw)
          raise ::API::Errors::InvalidRequestBody.new("The request body must be a JSON object.") unless body.is_a?(Hash)

          options = body.except(*REPORT_KEYS, "metadata").merge(Hash(body["metadata"]))
          [json_report(body), options]
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
