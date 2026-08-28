# frozen_string_literal: true

module RiskManagement
  class Configuration
    include ActiveModel::Model
    include ActiveModel::Attributes

    SETTING_ATTRIBUTES = %i[
      impact_very_low_max impact_low_max impact_medium_max impact_high_max
    ].freeze

    attribute :impact_very_low_max, :integer, default: 10_000
    attribute :impact_low_max, :integer, default: 50_000
    attribute :impact_medium_max, :integer, default: 100_000
    attribute :impact_high_max, :integer, default: 500_000

    validates :impact_very_low_max,
              :impact_low_max,
              :impact_medium_max,
              :impact_high_max,
              numericality: { greater_than_or_equal_to: 0 }
    validate :impact_thresholds_are_increasing
    validate :risk_type_is_available

    def self.load
      settings = Hash(Setting.plugin_openproject_risk_management).with_indifferent_access

      new(
        impact_very_low_max: settings[:impact_very_low_max] || 10_000,
        impact_low_max: settings[:impact_low_max] || 50_000,
        impact_medium_max: settings[:impact_medium_max] || 100_000,
        impact_high_max: settings[:impact_high_max] || 500_000
      )
    end

    def save # rubocop:disable Naming/PredicateMethod
      return false unless valid?

      Setting.plugin_openproject_risk_management = serialized_settings

      true
    end

    def persisted?
      false
    end

    def risk_type
      Type.find_by(builtin_identifier: "risk")
    end

    def risk_type_id
      risk_type&.id
    end

    private

    def serialized_settings
      SETTING_ATTRIBUTES.to_h { |attribute| [attribute.to_s, public_send(attribute).to_s] }
    end

    def impact_thresholds_are_increasing
      thresholds = [impact_very_low_max, impact_low_max, impact_medium_max, impact_high_max]
      return if thresholds.all?(&:present?) && thresholds.each_cons(2).all? { |lower, upper| lower < upper }

      errors.add(:base, I18n.t("risk_management.errors.impact_thresholds_must_increase"))
    end

    def risk_type_is_available
      errors.add(:base, I18n.t("risk_management.errors.risk_type_missing")) unless risk_type
    end
  end
end
