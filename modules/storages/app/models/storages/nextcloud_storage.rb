class Storages::NextcloudStorage < Storages::Storage
  store :provider_fields, accessors: %i[username password managed_folders]

  def managed_folders=(value)
    super(!!value)
  end

  def managed_folders
    !!super
  end
end
