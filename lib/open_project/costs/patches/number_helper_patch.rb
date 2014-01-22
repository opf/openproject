module OpenProject::Costs::Patches::NumberHelperPatch
  def self.included(base) # :nodoc:
    base.class_eval do
      include InstanceMethods

      alias_method_chain :number_to_currency, :l10n
    end
  end

  module InstanceMethods
    def number_to_currency_with_l10n(number, options = {})
      options_with_default = { unit: ERB::Util.h(Setting.plugin_openproject_costs['costs_currency']),
                               format: ERB::Util.h(Setting.plugin_openproject_costs['costs_currency_format']),
                               delimiter: l(:currency_delimiter),
                               separator: l(:currency_separator) }.merge(options)

      # FIXME: patch ruby instead of this code
      # this circumvents the broken BigDecimal#to_f on Siemens's ruby
      number = number.to_s if number.is_a? BigDecimal

      number_to_currency_without_l10n(number, options_with_default)
    end
  end
end
