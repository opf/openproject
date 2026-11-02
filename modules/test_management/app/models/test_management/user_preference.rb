# frozen_string_literal: true

module TestManagement
  # Per-user settings of the module (0019), see the migration for why core preferences are not used.
  class UserPreference < ApplicationRecord
    self.table_name = "tm_user_preferences"

    BOOLEAN_OPTIONS = %w[hotkey_tips hotkey_hints].freeze

    belongs_to :user

    validates :user_id, uniqueness: true

    store_accessor :options, :hotkey_tips, :hotkey_hints
    # Test Assistant provider picker (0021, Assistant::ProviderChoice): the picked provider and the
    # model picked per provider ({ "<provider id>" => "<model>" }).
    store_accessor :options, :assistant_provider_id, :assistant_models

    # Unsaved defaults for anonymous users and users without a row.
    def self.for(user)
      return new unless user.respond_to?(:logged?) && user.logged? && user.id

      find_or_initialize_by(user_id: user.id)
    end

    def hotkey_tips_enabled?
      option_on?(:hotkey_tips)
    end

    def hotkey_hints_enabled?
      option_on?(:hotkey_hints)
    end

    # Accepts "1"/"0"/"true"/"false"/booleans; other keys are ignored.
    def assign_options(values)
      values.to_h.each do |key, value|
        next unless BOOLEAN_OPTIONS.include?(key.to_s)

        public_send(:"#{key}=", ActiveModel::Type::Boolean.new.cast(value) == true)
      end
      self
    end

    private

    def option_on?(key)
      value = options.to_h[key.to_s]
      value.nil? || ActiveModel::Type::Boolean.new.cast(value) != false
    end
  end
end
