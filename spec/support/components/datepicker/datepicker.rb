module Components
  class Datepicker
    include Capybara::DSL
    include RSpec::Matchers
    attr_reader :context_selector

    def initialize(context = 'body')
      @context_selector = context
    end

    def container
      page.find("#{context_selector} .flatpickr-calendar")
    end

    ##
    # Select year from input
    def select_year(value)
      container
        .find('.numInput.cur-year')
        .set value
    end

    ##
    # Select month from select
    def select_month(value)
      container
        .find('.flatpickr-monthDropdown-months option', text: value, visible: :all)
        .select_option
    end

    ##
    # Select day from datepicker
    def select_day(value)
      unless (1..31).cover?(value.to_i)
        raise ArgumentError, "Invalid value #{value} for day, expected 1-31"
      end

      container
        .find('.flatpickr-days .flatpickr-day:not(.nextMonthDay):not(.prevMonthDay)',
              text: value,
              exact_text: true)
        .click
    end

    ##
    # Set a ISO8601 date through the datepicker
    def set_date(date)
      date = Date.parse(date) unless date.is_a?(Date)

      select_year date.year
      select_month date.strftime('%B')
      select_day date.day
    end

    ##
    # Expect the selected month
    def expect_month(month)
      month = Date::MONTHNAMES.index(month) if month.is_a?(String)

      # Month is 0-index in select
      field = container.find('.flatpickr-monthDropdown-months')
      expect(field.value.to_i).to eq(month - 1)
    end

    ##
    # Expect the selected day
    def expect_day(value)
      expect(container).to have_selector('.flatpickr-day.selected', text: value)
    end

    ##
    # Expect the selected year
    def expect_year(value)
      field = container.find('.cur-year')
      expect(field.value.to_i).to eq(value.to_i)
    end

    ##
    # Expect the current selection to match the
    # given ISO601 date
    def expect_current_date(date)
      date = Date.parse(date) unless date.is_a?(Date)

      expect_year(date.year)
      expect_month(date.month)
      expect_day(date.day)
    end
  end
end
