require "active_storage/filename"

module Projects
  class ExportJob < ::Exports::ExportJob
    self.model = Project

    private

    def prepare!
      self.query = ::Queries::Projects::ProjectQuery.from_hash(query)

      puts "*" * 100
      puts(query.orders)
      puts "*" * 100
    end
  end
end
