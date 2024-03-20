require 'active_storage/filename'

module WorkPackages
  class ExportJob < ::Exports::ExportJob
    self.model = WorkPackage

    def title
      I18n.t('export.your_work_packages_export')
    end

    private

    def prepare!
      self.query = set_query_props(query || Query.new, options[:query_attributes])
    end

    def set_query_props(query, query_attributes)
      filters = query_attributes.delete('filters')
      filters = Queries::WorkPackages::FilterSerializer.load(filters)

      query.tap do |q|
        q.attributes = query_attributes
        q.filters = filters
      end
    end
  end
end
