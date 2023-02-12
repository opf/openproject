RSpec.configure do |config|

  # Change `Date.beginning_of_week` in the context of the specs
  # according to the current locale.
  #
  # See also: https://github.com/opf/openproject/pull/12066
  #
  config.append_before do
    case I18n.locale
    when :en
      Date.beginning_of_week = :sunday
    when :de, :fr
      Date.beginning_of_week = :monday
    else
      Rails.logger.warn "First day of week not defined for locale #{I18n.locale} in spec/support/i18n.rb."
    end
  end
end
