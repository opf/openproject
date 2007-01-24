# Copyright (c) 2005-2006 David Barri

require 'date'

module ActionView #:nodoc:
  module Helpers #:nodoc:
    module DateHelper
    
      unless const_defined?(:LOCALIZED_HELPERS)
        LOCALIZED_HELPERS= true 
        LOCALIZED_MONTHNAMES = {}
        LOCALIZED_ABBR_MONTHNAMES = {}
      end
      
      # This method uses <tt>current_language</tt> to return a localized string.
      def distance_of_time_in_words(from_time, to_time = 0, include_seconds = false)
        from_time = from_time.to_time if from_time.respond_to?(:to_time)
        to_time = to_time.to_time if to_time.respond_to?(:to_time)
        distance_in_minutes = (((to_time - from_time).abs)/60).round
        distance_in_seconds = ((to_time - from_time).abs).round

        case distance_in_minutes
          when 0..1
            return (distance_in_minutes==0) ? l(:actionview_datehelper_time_in_words_minute_less_than) : l(:actionview_datehelper_time_in_words_minute_single) unless include_seconds
            case distance_in_seconds
              when 0..5   then lwr(:actionview_datehelper_time_in_words_second_less_than, 5)
              when 6..10  then lwr(:actionview_datehelper_time_in_words_second_less_than, 10)
              when 11..20 then lwr(:actionview_datehelper_time_in_words_second_less_than, 20)
              when 21..40 then l(:actionview_datehelper_time_in_words_minute_half)
              when 41..59 then l(:actionview_datehelper_time_in_words_minute_less_than)
              else             l(:actionview_datehelper_time_in_words_minute)
            end
                                
          when 2..45      then lwr(:actionview_datehelper_time_in_words_minute, distance_in_minutes)
          when 46..90     then l(:actionview_datehelper_time_in_words_hour_about_single)
          when 90..1440   then lwr(:actionview_datehelper_time_in_words_hour_about, (distance_in_minutes.to_f / 60.0).round)
          when 1441..2880 then lwr(:actionview_datehelper_time_in_words_day, 1)
          else                 lwr(:actionview_datehelper_time_in_words_day, (distance_in_minutes / 1440).round)
        end
      end

      # This method has been modified so that a localized string can be appended to the day numbers.
      def select_day(date, options = {})
        day_options = []
        prefix = l :actionview_datehelper_select_day_prefix

        1.upto(31) do |day|
          day_options << ((date && (date.kind_of?(Fixnum) ? date : date.day) == day) ?
            %(<option value="#{day}" selected="selected">#{day}#{prefix}</option>\n) :
            %(<option value="#{day}">#{day}#{prefix}</option>\n)
          )
        end

        select_html(options[:field_name] || 'day', day_options, options[:prefix], options[:include_blank], options[:discard_type], options[:disabled])
      end
      
      # This method has been modified so that
      # * the month names are localized.
      # * it uses options: <tt>:min_date</tt>, <tt>:max_date</tt>, <tt>:start_month</tt>, <tt>:end_month</tt>
      # * a localized string can be appended to the month numbers when the <tt>:use_month_numbers</tt> option is specified.
      def select_month(date, options = {})
        unless LOCALIZED_MONTHNAMES.has_key?(current_language)
          LOCALIZED_MONTHNAMES[current_language] = [''] + l(:actionview_datehelper_select_month_names).split(',')
          LOCALIZED_ABBR_MONTHNAMES[current_language] = [''] + l(:actionview_datehelper_select_month_names_abbr).split(',')
        end
        
        month_options = []
        month_names = options[:use_short_month] ? LOCALIZED_ABBR_MONTHNAMES[current_language] : LOCALIZED_MONTHNAMES[current_language]
        
        if options.has_key?(:min_date) && options.has_key?(:max_date)
          if options[:min_date].year == options[:max_date].year
            start_month, end_month = options[:min_date].month, options[:max_date].month
          end
        end
        start_month = (options[:start_month] || 1) unless start_month
        end_month = (options[:end_month] || 12) unless end_month
        prefix = l :actionview_datehelper_select_month_prefix

        start_month.upto(end_month) do |month_number|
          month_name = if options[:use_month_numbers]
            "#{month_number}#{prefix}"
          elsif options[:add_month_numbers]
            month_number.to_s + ' - ' + month_names[month_number]
          else
            month_names[month_number]
          end

          month_options << ((date && (date.kind_of?(Fixnum) ? date : date.month) == month_number) ?
            %(<option value="#{month_number}" selected="selected">#{month_name}</option>\n) :
            %(<option value="#{month_number}">#{month_name}</option>\n)
          )
        end

        select_html(options[:field_name] || 'month', month_options, options[:prefix], options[:include_blank], options[:discard_type], options[:disabled])
      end
      
      # This method has been modified so that
      # * it uses options: <tt>:min_date</tt>, <tt>:max_date</tt>
      # * a localized string can be appended to the years numbers.
      def select_year(date, options = {})
        year_options = []
        y = date ? (date.kind_of?(Fixnum) ? (y = (date == 0) ? Date.today.year : date) : date.year) : Date.today.year

        start_year = options.has_key?(:min_date) ? options[:min_date].year : (options[:start_year] || y-5)
        end_year = options.has_key?(:max_date) ? options[:max_date].year : (options[:end_year] || y+5)
        step_val = start_year < end_year ? 1 : -1
        prefix = l :actionview_datehelper_select_year_prefix

        start_year.step(end_year, step_val) do |year|
          year_options << ((date && (date.kind_of?(Fixnum) ? date : date.year) == year) ?
            %(<option value="#{year}" selected="selected">#{year}#{prefix}</option>\n) :
            %(<option value="#{year}">#{year}#{prefix}</option>\n)
          )
        end

        select_html(options[:field_name] || 'year', year_options, options[:prefix], options[:include_blank], options[:discard_type], options[:disabled])
      end

      # added by JP Lang
      # select_html is a rails private method and changed in 1.2
      # implementation added here for compatibility
      def select_html(type, options, prefix = nil, include_blank = false, discard_type = false, disabled = false)
        select_html  = %(<select name="#{prefix || "date"})
        select_html << "[#{type}]" unless discard_type
        select_html << %(")
        select_html << %( disabled="disabled") if disabled
        select_html << %(>\n)
        select_html << %(<option value=""></option>\n) if include_blank
        select_html << options.to_s
        select_html << "</select>\n"
      end
    end
    
    # The private method <tt>add_options</tt> is overridden so that "Please select" is localized.
    class InstanceTag
      private
      
      def add_options(option_tags, options, value = nil)
        option_tags = "<option value=\"\"></option>\n" + option_tags if options[:include_blank]
        
        if value.blank? && options[:prompt]
          ("<option value=\"\">#{options[:prompt].kind_of?(String) ? options[:prompt] : l(:actionview_instancetag_blank_option)}</option>\n") + option_tags
         else
          option_tags
        end
      end
      
    end
  end
end
