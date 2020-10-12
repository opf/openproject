module TwoFactorAuthentication
  class Device < ApplicationRecord
    default_scope { order('id ASC') }

    belongs_to :user
    validates_presence_of :user_id
    validates_presence_of :identifier

    # Check uniqueness of default for this type
    validate :cannot_set_default_if_exists

    def self.get_default
      find_by(default: true, active: true)
    end

    def self.get_active
      where(active: true)
    end

    def self.has_default?(user)
      Device.where(user_id: user.id, active: true, default: true).exists?
    end

    def has_default?
      self.class.has_default? user
    end

    ##
    # Make the device active, and set it as default if no other device exists
    def confirm_registration_and_save
      self.active = true
      self.default = !has_default?

      save
    end

    def identifier
      value = read_attribute(:identifier)

      if value
        value
      else
        default_identifier
      end
    end

    def redacted_identifier
      identifier
    end

    def default_identifier
      if user.present?
        "#{name} (#{user.login})"
      else
        name
      end
    end

    def name
      model_name.human
    end

    def active?
      active == true
    end

    def make_default!
      return false unless active?

      Device.transaction do
        Device.where(user_id: user_id).update_all(default: false)
        self.update_column(:default, true)
        return true
      end
    end

    def channel=(value)
      super value.to_sym
    end

    def channel
      value = read_attribute(:channel)
      return if value.nil?

      value.to_sym
    end

    def self.device_type
      raise NotImplementedError
    end

    def self.available_channels_in_strategy
      strategy_class = manager.get_strategy(device_type)
      strategy_class.supported_channels & self.supported_channels
    end

    private

    def self.manager
      ::OpenProject::TwoFactorAuthentication::TokenStrategyManager
    end

    def cannot_set_default_if_exists
      if default && has_default?
        errors.add :default, :default_already_exists
      end

      true
    end
  end
end
