class PermittedParams
  module AllowedSettings
    class Restriction
      attr_reader :restricted_keys, :condition

      def initialize(restricted_keys, condition)
        @restricted_keys = restricted_keys
        @condition = condition
      end

      def applicable?
        if condition.respond_to? :call
          condition.call
        else
          condition
        end
      end
    end

    module_function

    def all
      keys = Setting.available_settings.keys

      restrictions.select(&:applicable?).each do |restriction|
        restricted_keys = restriction.restricted_keys

        keys.delete_if { |key| restricted_keys.include? key }
      end

      keys
    end

    def add_restriction!(keys:, condition:)
      restrictions << Restriction.new(keys, condition)
    end

    def restrictions
      @restrictions ||= []
    end

    def init!
      password_keys = %w(
        password_min_length
        password_active_rules
        password_min_adhered_rules
        password_days_valid
        password_count_former_banned
        lost_password
      )

      add_restriction!(
        keys: password_keys,
        condition: -> { OpenProject::Configuration.disable_password_login? }
      )

      add_restriction!(
        keys: %w(registration_footer),
        condition: -> { OpenProject::Configuration.registration_footer.present? }
      )
    end

    init!
  end
end
