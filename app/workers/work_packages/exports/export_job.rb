module WorkPackages
  module Exports
    class ExportJob < ::ApplicationJob
      def perform(export:, user:, mime_type:, query:, query_attributes:, options:)
        User.execute_as user do
          query = set_query_props(query || Query.new, query_attributes)
          export_work_packages(export, mime_type, query, options)

          schedule_cleanup
        end
      end

      def status_reference
        arguments.first[:export]
      end

      def updates_own_status?
        true
      end

      protected

      def title
        I18n.t('export.your_work_packages_export')
      end

      private

      def export_work_packages(export, mime_type, query, options)
        exporter = WorkPackage::Exporter.for_list(mime_type)
        exporter.list(query, options) do |export_result|
          if export_result.error?
            raise export_result.message
          elsif export_result.content.is_a? File
            store_attachment(export, export_result.content)
          elsif export_result.content.is_a? Tempfile
            store_from_tempfile(export, export_result)
          else
            store_from_string(export, export_result)
          end
        end
      end

      def store_from_tempfile(export, export_result)
        renamed_file_path = File.join(File.dirname(export_result.content.path), export_result.title)
        File.rename(export_result.content.path, renamed_file_path)
        file = File.open(renamed_file_path)
        store_attachment(export, file)
        file.close
      end

      def schedule_cleanup
        ::WorkPackages::Exports::CleanupOutdatedJob.perform_after_grace
      end

      def set_query_props(query, query_attributes)
        filters = query_attributes.delete('filters')
        filters = Queries::WorkPackages::FilterSerializer.load(filters)

        query.tap do |q|
          q.attributes = query_attributes
          q.filters = filters
        end
      end

      def store_from_string(export, export_result)
        with_tempfile(export_result.title, export_result.content) do |file|
          store_attachment(export, file)
        end
      end

      def with_tempfile(title, content)
        name_parts = [title[0..title.rindex('.') - 1], title[title.rindex('.')..-1]]

        Tempfile.create(name_parts, encoding: content.encoding) do |file|
          file.write content

          yield file
        end
      end

      def store_attachment(storage, file)
        attachment = Attachments::CreateService
          .new(storage, author: User.current)
          .call(uploaded_file: file, description: '')

        download_url = ::API::V3::Utilities::PathHelper::ApiV3Path.attachment_content(attachment.id)

        upsert_status status: :success,
                      message: I18n.t('export.succeeded'),
                      payload: download_payload(download_url)
      end
    end
  end
end
