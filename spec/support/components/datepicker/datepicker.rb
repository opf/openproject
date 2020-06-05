module Components
  class Datepicker
    def initialize(context = '#content')
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
        raise ArgumentError, "Invalid value #{value}, expected 1-31"
      end

      container
        .find('.flatpickr-day', text: value)
        .click
    end

    ##
    # Set a ISO8601 date through the datepicker
    def set_date(date)
      date = Date.parse(date) unless date.is_a?(Date)

      select_year date.year
      select_month date.strftime('%B')
      click_on_day_in_current_month date.day
    end

    ##
    # Expect the current selection to match the
    # given ISO601 date
    def expect_current_date(date)
      date = Date.parse(date) unless date.is_a?(Date)

      expect(container).to have_selector('.cur-year', value: date.year)
      # Month is 0-index in select
      expect(container).to have_selector('.flatpickr-monthDropdown-months', value: date.month - 1)
      expect(container).to have_selector('.flatpickr-day.selected', text: date.day)
    end
  end
end
