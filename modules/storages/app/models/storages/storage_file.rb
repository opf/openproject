class Storages::StorageFile
  attr_reader :id, :name, :size, :mime_type, :created_at, :last_modified_at, :created_by_name, :last_modified_by_name, :location

  def initialize(id, name, size, mime_type, created_at, last_modified_at, created_by_name, last_modified_by_name, location)
    @id = id
    @name = name
    @size = size
    @mime_type = mime_type
    @created_at = created_at
    @last_modified_at = last_modified_at
    @created_by_name = created_by_name
    @last_modified_by_name = last_modified_by_name
    @location = location
  end
end
