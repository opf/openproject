class AnonymousUser < User
  validate :validate_unique_anonymous_user, on: :create

  # There should be only one AnonymousUser in the database
  def validate_unique_anonymous_user
    errors.add :base, 'An anonymous user already exists.' if AnonymousUser.any?
  end

  def available_custom_fields
    []
  end

  # Overrides a few properties
  def logged?; false end

  def builtin?; true end

  def admin; false end

  def name(*_args); I18n.t(:label_user_anonymous) end

  def mail; nil end

  def time_zone; nil end

  def rss_key; nil end

  def destroy; false end
end
