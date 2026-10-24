# frozen_string_literal: true

module RiskManagement
  module RiskLog
    class Assessment
      LEVELS = %i[very_low low medium high very_high].freeze
      RISK_LEVELS = %i[low medium high critical].freeze

      attr_reader :likelihood, :impact

      def initialize(likelihood:, impact:, configuration: Configuration.load)
        @likelihood = decimal(likelihood)
        @impact = decimal(impact)
        @configuration = configuration
      end

      def evaluated?
        likelihood&.between?(0, 100) && impact.present? && impact >= 0
      end

      def risk_value
        likelihood * impact / 100 if evaluated?
      end

      def likelihood_level
        return unless evaluated?

        LEVELS.fetch([(likelihood / 20).ceil, 1].max - 1)
      end

      def impact_level
        return unless evaluated?

        LEVELS.fetch(impact_thresholds.index { |threshold| impact <= threshold } || 4)
      end

      def coordinate
        return unless evaluated?

        [LEVELS.index(likelihood_level) + 1, LEVELS.index(impact_level) + 1]
      end

      def score
        coordinate&.reduce(:*)
      end

      def risk_level
        case score
        when 1..4 then :low
        when 5..9 then :medium
        when 10..16 then :high
        when 17..25 then :critical
        end
      end

      def high_or_critical?
        %i[high critical].include?(risk_level)
      end

      private

      def decimal(value)
        BigDecimal(value.to_s) if value.present?
      rescue ArgumentError
        nil
      end

      def impact_thresholds
        [
          @configuration.impact_very_low_max,
          @configuration.impact_low_max,
          @configuration.impact_medium_max,
          @configuration.impact_high_max
        ]
      end
    end
  end
end
