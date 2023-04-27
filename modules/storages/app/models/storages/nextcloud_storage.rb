class Storages::NextcloudStorage < Storages::Storage
  store :provider_fields, accessors: %i[username password has_managed_project_folders]

  alias_method :has_managed_project_folders?, :has_managed_project_folders

  def has_managed_project_folders=(value)
    super(!!value)
  end

  # rubocop:disable Naming/PredicateName
  def has_managed_project_folders
    !!super
  end
  # rubocop:enable Naming/PredicateName
end
