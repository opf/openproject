module IceCube
  class IcalParser
    def self.schedule_from_ical(ical_string, options = {})
      data = {}
      ical_string.each_line do |line|
        (property, value) = line.split(':')
        (property, tzid) = property.split(';')
        case property
        when 'DTSTART'
          data[:start_time] = TimeUtil.deserialize_time(value)
        when 'DTEND'
          data[:end_time] = TimeUtil.deserialize_time(value)
        when 'RDATE'
          data[:rtimes] ||= []
          data[:rtimes] += value.split(',').map { |v| TimeUtil.deserialize_time(v) }
        when 'EXDATE'
          data[:extimes] ||= []
          data[:extimes] += value.split(',').map { |v| TimeUtil.deserialize_time(v) }
        when 'DURATION'
          data[:duration] # FIXME
        when 'RRULE'
          data[:rrules] ||= []
          data[:rrules] += [rule_from_ical(value)]
        end
      end
      Schedule.from_hash data
    end

    def self.rule_from_ical(ical)
      raise ArgumentError, 'empty ical rule' if ical.nil?

      validations = {}
      params = {validations: validations, interval: 1}

      ical.split(';').each do |rule|
        (name, value) = rule.split('=')
        raise ArgumentError, "Invalid iCal rule component" if value.nil?
        value.strip!
        case name
        when 'FREQ'
          params[:rule_type] = "IceCube::#{value[0]}#{value.downcase[1..-1]}Rule"
        when 'INTERVAL'
          params[:interval] = value.to_i
        when 'COUNT'
          params[:count] = value.to_i
        when 'UNTIL'
          params[:until] = TimeUtil.deserialize_time(value).utc
        when 'WKST'
          params[:week_start] = TimeUtil.ical_day_to_symbol(value)
        when 'BYSECOND'
          validations[:second_of_minute] = value.split(',').map(&:to_i)
        when 'BYMINUTE'
          validations[:minute_of_hour] = value.split(',').map(&:to_i)
        when 'BYHOUR'
          validations[:hour_of_day] = value.split(',').map(&:to_i)
        when 'BYDAY'
          dows = {}
          days = []
          value.split(',').each do |expr|
            day = TimeUtil.ical_day_to_symbol(expr.strip[-2..-1])
            if expr.strip.length > 2  # day with occurence
              occ = expr[0..-3].to_i
              dows[day].nil? ? dows[day] = [occ] : dows[day].push(occ)
              days.delete(TimeUtil.sym_to_wday(day))
            else
              days.push TimeUtil.sym_to_wday(day) if dows[day].nil?
            end
          end
          validations[:day_of_week] = dows unless dows.empty?
          validations[:day] = days unless days.empty?
        when 'BYMONTHDAY'
          validations[:day_of_month] = value.split(',').map(&:to_i)
        when 'BYMONTH'
          validations[:month_of_year] = value.split(',').map(&:to_i)
        when 'BYYEARDAY'
          validations[:day_of_year] = value.split(',').map(&:to_i)
        when 'BYSETPOS'
        else
          validations[name] = nil # invalid type
        end
      end

      Rule.from_hash(params)
    end
  end
end
