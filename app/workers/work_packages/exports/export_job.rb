module WorkPackages
  module Exports
    class ExportJob < ::ApplicationJob
      def perform(export:, mime_type:, query:, options:)
        User.execute_as export.user do
          export_work_packages(export, mime_type, query, options)

          schedule_cleanup
        end
      end

      private

      def export_work_packages(export, mime_type, query_props, options)
        exporter = WorkPackage::Exporter.for_list(mime_type)
        exporter.list(query(query_props), options) do |export_result|
          if export_result.error?
            raise export_result.message
          elsif export_result.content.is_a? File
            store_attachment(export, export_result.content)
          else
            store_from_string(export, export_result)
          end
        end
      end

      def schedule_cleanup
        ::WorkPackages::Exports::CleanupOutdatedJob.perform_after_grace
      end

      def query(query_props)
        if query_props.is_a?(Query)
          query_props
        else
          filters = query_props.delete('filters')
          filters = Queries::WorkPackages::FilterSerializer.load(filters)

          Query.new(query_props).tap do |q|
            q.filters = filters
            q.set_context
          end
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
        Attachments::CreateService
          .new(storage, author: storage.user)
          .call(uploaded_file: file, description: '')
      end
    end
  end
end
