#
# User for tasks like migrations
#

class SystemUser < User

  validate :validate_unique_system_user, :on => :create

  # There should be only one AutomaticMigrationUser in the database
  def validate_unique_system_user
    errors.add :base, 'A SystemUser already exists.' if SystemUser.find(:first)
  end

  def available_custom_fields
    []
  end

  # Overrides a few properties
  def logged?; false end
  def name(*args); "System" end
  def mail; nil end
  def time_zone; nil end
  def rss_key; nil end
  def destroy; false end

  def grant_privileges
    self.admin = true
    self.status = STATUS_BUILTIN
    self.save
  end

  def remove_privileges
    self.admin = false
    self.status = User::STATUS_LOCKED
    self.save
  end

  def run_given(&block)
    if block_given?
      grant_privileges
      old_user = User.current
      User.current = self

      begin
        yield
      ensure
        remove_privileges
        User.current = old_user
      end
    else
      raise 'no block given'
    end
  end
end
