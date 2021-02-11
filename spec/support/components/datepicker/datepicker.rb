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
        .first('.numInput.cur-year')
        .set value
    end

    ##
    # Select month from datepicker
    def select_month(month, multiple_month_shown = false)
      if multiple_month_shown
        month = Date::MONTHNAMES.index(month) if month.is_a?(String)
        current_month = Date::MONTHNAMES.index(container.first('.cur-month').text)

        if current_month < month
          while current_month < month
            container.find('.flatpickr-next-month').click
            current_month = Date::MONTHNAMES.index(container.first('.cur-month').text)
          end
        elsif current_month > month
          while current_month > month
            container.find('.flatpickr-prev-month').click
            current_month = Date::MONTHNAMES.index(container.first('.cur-month').text)
          end
        end
      else
        container
          .first('.flatpickr-monthDropdown-months option', text: month, visible: :all)
          .select_option
      end
    end

    ##
    # Select day from datepicker
    def select_day(value)
      unless (1..31).cover?(value.to_i)
        raise ArgumentError, "Invalid value #{value} for day, expected 1-31"
      end

      container
        .first('.flatpickr-days .flatpickr-day:not(.nextMonthDay):not(.prevMonthDay)',
               text: value,
               exact_text: true)
        .click
    end

    ##
    # Set a ISO8601 date through the datepicker
    def set_date(date, multiple_month_shown = false)
      date = Date.parse(date) unless date.is_a?(Date)

      select_year date.year
      select_month multiple_month_shown ? date.month : date.strftime('%B'), multiple_month_shown
      select_day date.day
    end

    ##
    # Expect the selected month
    def expect_month(month, multiple_month_shown = false)
      if multiple_month_shown
        field = container.first('.cur-month')
        expect(field.text).to eq(month)
      else
        month = Date::MONTHNAMES.index(month) if month.is_a?(String)

        # Month is 0-index in select
        field = container.find('.flatpickr-monthDropdown-months')
        expect(field.value.to_i).to eq(month - 1)

      end
    end

    ##
    # Expect the selected day
    def expect_day(value)
      expect(container).to have_selector('.flatpickr-day.selected', text: value)
    end

    ##
    # Expect the selected year
    def expect_year(value)
      field = container.first('.cur-year')
      expect(field.value.to_i).to eq(value.to_i)
    end

    ##
    # Expect the current selection to match the
    # given ISO601 date
    def expect_current_date(date, multiple_month_shown = false)
      date = Date.parse(date) unless date.is_a?(Date)

      expect_year(date.year)
      expect_month(date.month, multiple_month_shown)
      expect_day(date.day)
    end
  end
end
