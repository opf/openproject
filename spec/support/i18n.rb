RSpec.configure do |config|
  # Change `Date.beginning_of_week` in the context of the specs
  # according to the current locale.
  #
  # Usage:
  #
  #    context "with Date.beginning_of_week based on I18n.locale", beginning_of_week: :locale
  #    context "with Date.beginning_of_week set on :sunday", beginning_of_week: :sunday
  #
  # See also: https://github.com/opf/openproject/pull/12066
  #
  config.append_before do |example|
    beginning_of_week = example.metadata[:beginning_of_week]
    if beginning_of_week == :locale
      set_beginning_of_week_based_on_locale
    elsif beginning_of_week.present? and beginning_of_week.is_a? Symbol
      Date.beginning_of_week = beginning_of_week
    end
  end

  def set_beginning_of_week_based_on_locale
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
