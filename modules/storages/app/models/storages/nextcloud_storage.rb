class Storages::NextcloudStorage < Storages::Storage
  store :provider_fields, accessors: %i[username password has_managed_project_folders]

  def has_managed_project_folders=(value)
    super(!!value)
  end

  def has_managed_project_folders
    !!super
  end
end
