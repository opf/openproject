class DeletedUser < User
  def self.first
    super || create(type: to_s, status: statuses[:locked])
  end

  include Users::FunctionUser

  def name(*_args) = I18n.t("user.deleted")
end
