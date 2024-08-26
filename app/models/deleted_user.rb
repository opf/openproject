class DeletedUser < User
  validate :validate_unique_deleted_user, on: :create

  # There should be only one DeletedUser in the database
  def validate_unique_deleted_user
    errors.add :base, "A DeletedUser already exists." if DeletedUser.any?
  end

  def self.first
    super || create(type: to_s, status: statuses[:locked])
  end

  # Overrides a few properties
  def available_custom_fields = []
  def logged? = false
  def builtin? = true
  def admin = false
  def name(*_args) = I18n.t("user.deleted")
  def mail = nil
  def time_zone = nil
  def rss_key = nil
  def destroy = false
end
