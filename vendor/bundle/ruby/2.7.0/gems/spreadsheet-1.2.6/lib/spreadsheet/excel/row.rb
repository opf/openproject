require 'date'
require 'spreadsheet/row'

module Spreadsheet
  module Excel
##
# Excel-specific Row methods
class Row < Spreadsheet::Row
  ##
  # The Excel date calculation erroneously assumes that 1900 is a leap-year. All
  # Dates after 28.2.1900 are off by one.
  LEAP_ERROR = Date.new 1900, 2, 28
  ##
  # Force convert the cell at _idx_ to a Date
  def date idx
    _date at(idx)
  end
  ##
  # Force convert the cell at _idx_ to a DateTime
  def datetime idx
    _datetime at(idx)
  end
  def each
    size.times do |idx|
      yield self[idx]
    end
  end
  ##
  # Access data in this Row like you would in an Array. If a cell is formatted
  # as a Date or DateTime, the decoded Date or DateTime value is returned.
  def [] idx, len=nil
    if len
      idx = idx...(idx+len)
    end
    if idx.is_a? Range
      data = []
      idx.each do |i|
        data.push enriched_data(i, at(i))
      end
      data
    else
      enriched_data idx, at(idx)
    end
  end
  ##
  # Returns data as an array. If a cell is formatted as a Date or DateTime, the
  # decoded Date or DateTime value is returned.
  def to_a
    self[0...length]
  end
  private
  def _date data # :nodoc:
    return data if data.is_a?(Date)
    datetime = _datetime data
    Date.new datetime.year, datetime.month, datetime.day
  end
  def _datetime data # :nodoc:
    return data if data.is_a?(DateTime)
    base = @worksheet.date_base
    date = base + data.to_f
    hour = (data.to_f % 1) * 24
    min  = (hour % 1) * 60
    sec  = ((min % 1) * 60).round
    min = min.floor
    hour = hour.floor
    if sec > 59
      sec = 0
      min += 1
    end
    if min > 59
      min = 0
      hour += 1
    end
    if hour > 23
      hour = 0
      date += 1
    end
    if LEAP_ERROR > base
      date -= 1
    end
    DateTime.new(date.year, date.month, date.day, hour, min, sec)
  end
  def enriched_data idx, data # :nodoc:
    res = nil
    if link = @worksheet.links[[@idx, idx]]
      res = link
    elsif data.is_a?(Numeric) && fmt = format(idx)
      res = if fmt.datetime? || fmt.time?
              _datetime data
            elsif fmt.date?
              _date data
            end
    end
    res || data
  end
end
  end
end
