# frozen_string_literal: true

module TestManagement
  module Automation
    # Stores uploaded CI artifacts (screenshots, traces, videos, HTML report) as
    # OpenProject attachments, through Attachments::CreateService so the
    # attachment size limit, content-type allow list and permissions apply.
    # - a file listed for a test in the report goes to that test's run case. Files
    #   are matched by path: the upload's relative path (`attachmentPaths`, else its
    #   file name) must be a suffix of the path in the report; the longest match wins,
    #   so equally named files from different test folders end up on the right case;
    # - every other file goes to the run (e.g. playwright-report.zip).
    class AttachmentWriter
      MAX_FILES = 200

      attr_reader :created

      def initialize(user:, run:, files:, warnings:, paths: [])
        @user = user
        @run = run
        @files = Array(files).first(MAX_FILES)
        @warnings = warnings
        @created = []
        warnings << { "code" => "too_many_attachments", "max" => MAX_FILES } if Array(files).size > MAX_FILES
        @keys = {}.compare_by_identity
        @files.each_with_index { |file, index| @keys[file] = normalize(paths[index].presence || basename(file)) }
        @used = {}.compare_by_identity
      end

      # Attach the files listed for `record` to `run_case`; returns attachment ids. The ids by listed
      # path are kept in #ids_by_path (step results link their screenshots, 0020).
      def attach_for(record, run_case)
        record.attachments.filter_map do |listed|
          file = best_match(normalize(listed["path"]))
          next unless file

          @used[file] = true
          store(run_case, file, listed["name"]).tap { |id| ids_by_path[listed["path"].to_s] = id if id }
        end
      end

      def ids_by_path
        @ids_by_path ||= {}
      end

      # Files not referenced by any test: attached to the run.
      def attach_rest
        @files.reject { |file| @used[file] }.each do |file|
          @used[file] = true
          store(run, file, nil)
        end
      end

      private

      attr_reader :user, :run, :warnings

      def best_match(listed_path)
        return if listed_path.blank?

        @files.reject { |file| @used[file] }
              .select { |file| suffix?(listed_path, @keys[file]) }
              .max_by { |file| @keys[file].length }
      end

      def suffix?(path, key)
        key.present? && (path == key || path.end_with?("/#{key}"))
      end

      def normalize(path)
        path.to_s.tr("\\", "/").delete_prefix("./")
      end

      def basename(file)
        File.basename((file.respond_to?(:original_filename) && file.original_filename).presence || file.path.to_s)
      end

      def store(container, file, description)
        call = ::Attachments::CreateService
                 .new(user:)
                 .call(container:, file:, filename: basename(file), description: description.presence)
        if call.success?
          created << { "id" => call.result.id, "fileName" => call.result.filename,
                       "container" => container.class.name.demodulize, "containerId" => container.id }
          call.result.id
        else
          warnings << { "code" => "attachment_rejected", "fileName" => basename(file),
                        "errors" => call.errors.full_messages }
          nil
        end
      rescue StandardError => e
        warnings << { "code" => "attachment_failed", "fileName" => basename(file), "errors" => [e.message.to_s.first(300)] }
        nil
      end
    end
  end
end
