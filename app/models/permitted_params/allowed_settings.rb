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
      keys = Settings::Definition.all.keys

      restrictions.select(&:applicable?).each do |restriction|
        keys -= restriction.restricted_keys
      end

      keys
    end

    def filters
      restricted_keys = Set.new(self.restricted_keys)
      Settings::Definition.all.flat_map do |key, definition|
        next if restricted_keys.include?(key)

        case definition.format
        when :hash
          { key => {} }
        when :array
          { key => [] }
        else
          key
        end
      end
    end

    def restricted_keys
      restrictions.select(&:applicable?)
                  .flat_map(&:restricted_keys)
    end

    def add_restriction!(keys:, condition:)
      restrictions << Restriction.new(keys, condition)
    end

    def restrictions
      @restrictions ||= []
    end

    def init!
      password_keys = %i(
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
        keys: %i(registration_footer),
        condition: -> { !Setting.registration_footer_writable? }
      )
    end

    init!
  end
end
