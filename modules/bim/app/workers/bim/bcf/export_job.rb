module Bim
  module Bcf
    class ExportJob < ::ApplicationJob
      def perform(export:, work_package_ids:)
        User.execute_as export.user do
          OpenProject::Bim::BcfXml::Exporter.list(query(work_package_ids)) do |export_result|
            if export_result.error?
              raise export_result.message
            else
              store_attachment(export, export_result)
            end
          end

          schedule_cleanup
        end
      end

      private

      def store_attachment(storage, result)
        Attachments::CreateService
          .new(storage, author: storage.user)
          .call(uploaded_file: result.content, description: '')
      end

      def schedule_cleanup
        ::WorkPackages::Exports::CleanupOutdatedJob.perform_after_grace
      end

      def query(work_package_ids)
        Query.new(name: '_').tap do |query|
          query.add_filter('id', '=', work_package_ids)
        end
      end
    end
  end
end
