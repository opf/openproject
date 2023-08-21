class DeletedUser < User
  validate :validate_unique_deleted_user, on: :create

  # There should be only one DeletedUser in the database
  def validate_unique_deleted_user
    errors.add :base, 'A DeletedUser already exists.' if DeletedUser.any?
  end

  def self.first
    super || create(type: to_s, status: statuses[:locked])
  end

  # Overrides a few properties
  def logged?; false end

  def builtin?; true end

  def admin; false end

  def name(*_args); I18n.t('user.deleted') end

  def mail; nil end

  def time_zone; nil end

  def rss_key; nil end

  def destroy; false end
end
