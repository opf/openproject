require 'active_storage/filename'

module Projects
  class ExportJob < ::Exports::ExportJob
    self.model = Project

    private

    def prepare!
      self.query = Marshal.load(query)
    end
  end
end
