require 'active_storage/filename'

module Exports
  class ExportJob < ::ApplicationJob
    queue_with_priority :above_normal

    def perform(export:, user:, mime_type:, query:, **options)
      self.export = export
      self.current_user = user
      self.mime_type = mime_type
      self.query = query
      self.options = options.with_indifferent_access

      User.execute_as(user) do
        prepare!
        export!
        schedule_cleanup
      rescue StandardError => e
        Rails.logger.error "Failed to run export job for #{user}: #{e.message}"
        raise e
      end
    end

    def status_reference
      arguments.first[:export]
    end

    def updates_own_status?
      true
    end

    protected

    class_attribute :model

    attr_accessor :export, :current_user, :mime_type, :query, :options

    def prepare!
      raise NotImplementedError
    end

    def export!
      result = exporter_instance.export!
      handle_export_result(export, result)
    end

    def exporter_instance
      ::Exports::Register
        .list_exporter(model, mime_type)
        .new(query, options)
    end

    def handle_export_result(export, result)
      case result.content
      when File
        store_attachment(export, result.content, result)
      when Tempfile
        store_from_tempfile(export, result)
      else
        store_from_string(export, result)
      end
    end

    def store_from_tempfile(export, export_result)
      renamed_file_path = target_file_name(export_result)
      File.rename(export_result.content.path, renamed_file_path)
      file = File.open(renamed_file_path)
      store_attachment(export, file, export_result)
      file.close
    end

    ##
    # Create a target file name, replacing any invalid characters
    def target_file_name(export_result)
      File.join(File.dirname(export_result.content.path), clean_filename(export_result))
    end

    def schedule_cleanup
      CleanupOutdatedJob.perform_after_grace
    end

    def clean_filename(export_result)
      ActiveStorage::Filename.new(export_result.title).sanitized
    end

    def store_from_string(export, export_result)
      with_tempfile(export_result.title, export_result.content) do |file|
        store_attachment(export, file, export_result)
      end
    end

    def with_tempfile(title, content)
      name_parts = [title[0..title.rindex('.') - 1], title[title.rindex('.')..]]

      Tempfile.create(name_parts, encoding: content.encoding) do |file|
        file.write content

        yield file
      end
    end

    def store_attachment(container, file, export_result)
      filename = clean_filename(export_result)

      call = Attachments::CreateService
               .bypass_whitelist(user: User.current)
               .call(container:, file:, filename:, description: '')

      call.on_success do
        download_url = ::API::V3::Utilities::PathHelper::ApiV3Path.attachment_content(call.result.id)

        upsert_status status: :success,
                      message: I18n.t('export.succeeded'),
                      payload: download_payload(download_url)
      end

      call.on_failure do
        upsert_status status: :failure,
                      message: I18n.t('export.failed', message: call.message)
      end
    end
  end
end
