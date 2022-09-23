class Storages::StorageFile
  attr_reader :id, :name, :mime_type, :created_at, :last_modified_at, :created_by_name, :last_modified_by_name, :location

  def initialize(id, name, mime_type, created_at, last_modified_at, created_by_name, last_modified_by_name, location)
    @id = id
    @name = name
    @mime_type = mime_type
    @created_at = created_at
    @last_modified_at = last_modified_at
    @created_by_name = created_by_name
    @last_modified_by_name = last_modified_by_name
    @location = location
  end

  def self.all
    [
      {
        id: 1,
        name: 'image.png',
        mimeType: 'image/png',
        lastModifiedAt: '2022-09-16T12:00Z',
        lastModifiedByName: 'Leia Organa',
        location: '/data'
      },
      {
        id: 2,
        name: 'Readme.md',
        mimeType: 'text/markdown',
        lastModifiedAt: '2022-09-16T13:00Z',
        lastModifiedByName: 'Anakin Skywalker',
        location: '/data'
      },
      {
        id: 3,
        name: 'folder',
        mimeType: 'application/x-op-directory',
        location: '/data'
      },
      {
        id: 4,
        name: 'directory',
        mimeType: 'application/x-op-directory',
        location: '/data'
      }
    ].map { |obj| ::Storages::StorageFile.new(obj[:id], obj[:name], obj[:mimeType], nil, obj[:lastModifiedAt], nil, obj[:lastModifiedByName], obj[:location]) }
  end
end
