module Components
  class Datepicker
    include Capybara::DSL
    include Capybara::RSpecMatchers
    include RSpec::Matchers
    attr_reader :context_selector

    def initialize(context = 'body')
      @context_selector = context
    end

    def container
      page.find(context_selector)
    end

    def flatpickr_container
      container.find(".flatpickr-calendar")
    end

    ##
    # Clear all values
    def clear!
      focus_start_date
      fill_in 'startDate', with: '', fill_options: { clear: :backspace }

      focus_due_date
      fill_in 'endDate', with: '', fill_options: { clear: :backspace }
    end

    def expect_visible
      expect(container).to have_selector('.flatpickr-calendar .flatpickr-current-month', wait: 10)
    end

    ##
    # Select year from input
    def select_year(value)
      retry_block do
        flatpickr_container
          .first('.numInput.cur-year')
          .set value
      end
    end

    ##
    # Select month from datepicker
    def select_month(month)
      flatpickr_container
        .first('.flatpickr-monthDropdown-months option', text: month, visible: :all)
        .select_option
    end

    ##
    # Select day from datepicker
    def select_day(value)
      unless (1..31).cover?(value.to_i)
        raise ArgumentError, "Invalid value #{value} for day, expected 1-31"
      end

      retry_block do
        flatpickr_container
          .first('.flatpickr-days .flatpickr-day:not(.nextMonthDay):not(.prevMonthDay)',
                 text: value,
                 exact_text: true)
          .click
      end
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
      field = flatpickr_container.find('.flatpickr-monthDropdown-months')
      expect(field.value.to_i).to eq(month - 1)

    end

    ##
    # Expect the selected day
    def expect_day(value)
      expect(flatpickr_container).to have_selector('.flatpickr-day.selected', text: value)
    end

    ##
    # Expect the selected year
    def expect_year(value)
      expect(flatpickr_container).to have_selector('.cur-year') do |field|
        field.value.to_i == value.to_i
      end
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
