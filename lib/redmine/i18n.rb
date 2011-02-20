module Redmine
  module I18n
    def self.included(base)
      base.extend Redmine::I18n
    end
      
    def l(*args)
      case args.size
      when 1
        ::I18n.t(*args)
      when 2
        if args.last.is_a?(Hash)
          ::I18n.t(*args)
        elsif args.last.is_a?(String)
          ::I18n.t(args.first, :value => args.last)
        else
          ::I18n.t(args.first, :count => args.last)
        end
      else
        raise "Translation string with multiple values: #{args.first}"
      end
    end

    def l_or_humanize(s, options={})
      k = "#{options[:prefix]}#{s}".to_sym
      ::I18n.t(k, :default => s.to_s.humanize)
    end
    
    def l_hours(hours)
      hours = hours.to_f
      l((hours < 2.0 ? :label_f_hour : :label_f_hour_plural), :value => ("%.2f" % hours.to_f))
    end
    
    def ll(lang, str, value=nil)
      ::I18n.t(str.to_s, :value => value, :locale => lang.to_s.gsub(%r{(.+)\-(.+)$}) { "#{$1}-#{$2.upcase}" })
    end

    def format_date(date)
      return nil unless date
      Setting.date_format.blank? ? ::I18n.l(date.to_date) : date.strftime(Setting.date_format)
    end
    
    def format_time(time, include_date = true)
      return nil unless time
      time = time.to_time if time.is_a?(String)
      zone = User.current.time_zone
      local = zone ? time.in_time_zone(zone) : (time.utc? ? time.localtime : time)
      (include_date ? "#{format_date(local)} " : "") +
        (Setting.time_format.blank? ? ::I18n.l(local, :format => :time) : local.strftime(Setting.time_format))
    end

    def day_name(day)
      ::I18n.t('date.day_names')[day % 7]
    end
  
    def month_name(month)
      ::I18n.t('date.month_names')[month]
    end
    
    def valid_languages
      @@valid_languages ||= Dir.glob(File.join(RAILS_ROOT, 'config', 'locales', '*.yml')).collect {|f| File.basename(f).split('.').first}.collect(&:to_sym)
    end
    
    def find_language(lang)
      @@languages_lookup = valid_languages.inject({}) {|k, v| k[v.to_s.downcase] = v; k }
      @@languages_lookup[lang.to_s.downcase]
    end
    
    def set_language_if_valid(lang)
      if l = find_language(lang)
        ::I18n.locale = l
      end
    end
    
    def current_language
      ::I18n.locale
    end
  end
end
