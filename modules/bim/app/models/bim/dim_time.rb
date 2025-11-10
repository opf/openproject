# frozen_string_literal: true

module Bim
  # Time dimension table (pre-populated calendar)
  # Enables efficient time-based analytics and reporting
  class DimTime < ApplicationRecord
    self.table_name = 'bim_dim_time'
    self.primary_key = 'date_key'

    # Scopes
    scope :in_year, ->(year) { where(year: year) }
    scope :in_quarter, ->(year, quarter) { where(year: year, quarter: quarter) }
    scope :in_month, ->(year, month) { where(year: year, month: month) }
    scope :weekends, -> { where(is_weekend: true) }
    scope :weekdays, -> { where(is_weekend: false) }
    scope :holidays, -> { where(is_holiday: true) }
    scope :working_days, -> { where(is_weekend: false, is_holiday: false) }
    scope :between_dates, ->(start_date, end_date) { where(date_key: start_date..end_date) }

    # Class methods
    class << self
      # Populate time dimension table with date range
      def populate!(start_date: Date.new(2020, 1, 1), end_date: Date.new(2030, 12, 31), fiscal_year_start_month: 1)
        dates_to_insert = []

        (start_date..end_date).each do |date|
          dates_to_insert << build_time_record(date, fiscal_year_start_month)

          # Batch insert every 1000 records
          if dates_to_insert.size >= 1000
            insert_all(dates_to_insert, unique_by: :date_key)
            dates_to_insert = []
          end
        end

        # Insert remaining records
        insert_all(dates_to_insert, unique_by: :date_key) if dates_to_insert.any?
      end

      # Build time dimension record for a date
      def build_time_record(date, fiscal_year_start_month = 1)
        year = date.year
        quarter = ((date.month - 1) / 3) + 1
        month = date.month
        week = date.cweek
        day_of_week = date.wday
        day_of_month = date.day
        day_of_year = date.yday
        is_weekend = [0, 6].include?(day_of_week)

        # Fiscal year calculation
        fiscal_year = if date.month >= fiscal_year_start_month
                        year
                      else
                        year - 1
                      end

        fiscal_month_offset = fiscal_year_start_month - 1
        fiscal_month = ((month - fiscal_month_offset - 1) % 12) + 1
        fiscal_quarter = ((fiscal_month - 1) / 3) + 1

        {
          date_key: date,
          year: year,
          quarter: quarter,
          month: month,
          week: week,
          day_of_week: day_of_week,
          day_of_month: day_of_month,
          day_of_year: day_of_year,
          is_weekend: is_weekend,
          is_holiday: false,  # Can be updated later with holiday data
          holiday_name: nil,
          fiscal_year: fiscal_year,
          fiscal_quarter: fiscal_quarter,
          fiscal_month: fiscal_month,
          year_month: date.strftime('%Y-%m'),
          year_quarter: "#{year}-Q#{quarter}",
          week_start_date: date.beginning_of_week.strftime('%Y-%m-%d')
        }
      end

      # Mark holidays in the dimension table
      def mark_holidays!(holidays)
        # holidays should be a hash: { Date => 'Holiday Name' }
        holidays.each do |date, name|
          where(date_key: date).update_all(is_holiday: true, holiday_name: name)
        end
      end

      # Get or create time dimension record for a date
      def for_date(date)
        find_or_create_by!(date_key: date) do |record|
          attributes = build_time_record(date)
          record.assign_attributes(attributes)
        end
      end
    end

    # Instance methods

    # Get previous day
    def previous_day
      self.class.find_by(date_key: date_key - 1.day)
    end

    # Get next day
    def next_day
      self.class.find_by(date_key: date_key + 1.day)
    end

    # Get first day of month
    def month_start
      self.class.find_by(date_key: date_key.beginning_of_month)
    end

    # Get last day of month
    def month_end
      self.class.find_by(date_key: date_key.end_of_month)
    end

    # Get first day of quarter
    def quarter_start
      self.class.find_by(date_key: date_key.beginning_of_quarter)
    end

    # Get last day of quarter
    def quarter_end
      self.class.find_by(date_key: date_key.end_of_quarter)
    end

    # Get first day of year
    def year_start
      self.class.find_by(date_key: date_key.beginning_of_year)
    end

    # Get last day of year
    def year_end
      self.class.find_by(date_key: date_key.end_of_year)
    end

    # Display formats
    def to_s
      date_key.strftime('%Y-%m-%d')
    end

    def display_date
      date_key.strftime('%B %d, %Y')
    end

    def day_name
      Date::DAYNAMES[day_of_week]
    end

    def month_name
      Date::MONTHNAMES[month]
    end

    def quarter_name
      "Q#{quarter}"
    end
  end
end
