#
# User for tasks like migrations
#

class SystemUser < User
  module DisableCustomizable
    def self.included(base)
      # Prevent save_custom_field_values method from running.
      # I am not sure why this is necessary so this can be considered a hack.
      #
      # The symptoms are, that saving User.system, which will happen when calling
      # User.system.run_given, from inside a migration fails.
      #
      # The callback sends self.custom_values which leads to an eror
      # stating that no column "name", "default_value" or "possible_values"
      # exists in the db. It is correct that such a field does not exist, as those are
      # translated attributes so that they are to be found in custom_field_translations.
      #
      # It seems to me that CustomField is not correctly instrumented by globalize3 which
      # should delegate attribute assignment to any such column to the translation table.

      base.skip_callback :save, :after, :save_custom_field_values
    end

    def available_custom_fields
      []
    end
  end

  include DisableCustomizable

  validate :validate_unique_system_user, :on => :create

  # There should be only one SystemUser in the database
  def validate_unique_system_user
    errors.add :base, 'A SystemUser already exists.' if SystemUser.find(:first)
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
    self.status = STATUSES[:builtin]
    self.save
  end

  def remove_privileges
    self.admin = false
    self.status = STATUSES[:locked]
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
